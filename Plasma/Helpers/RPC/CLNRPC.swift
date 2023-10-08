//
//  CLNRPC.swift
//  FullyNoded
//
//  Created by Peter Denton on 9/15/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation


public typealias RequestRes<T> = Result<T, RequestError<RpcErrorData>>

public struct ResultWrapper<T: Decodable>: Decodable {
    public var result: T
}

public struct ErrorWrapper<T: Decodable>: Decodable {
    public var error: T
}

public struct RpcErrorData: Decodable, CustomStringConvertible {
    public var message: String

    public var description: String {
        return message
    }
}

public enum Either<L, R> {
    case left(L)
    case right(R)

    func mapError<L2>(mapper: (L) -> L2) -> Either<L2, R> {
        switch self {
        case .left(let l1):
            return .left(mapper(l1))
        case .right(let r):
            return .right(r)
        }
    }
}

public enum RequestErrorType: Error {
    case decoding(DecodingError)
    case connectionFailed
    case initFailed
    case writeFailed
    case timeout
    case selectFailed
    case recvFailed
    case badCommandoMsgType(Int)
    case badConnectionString
    case outOfMemory
    case encoding(EncodingError)
    case status(Int)
    case unknown(String)
}

public struct RequestError<E: CustomStringConvertible & Decodable>: Error, CustomStringConvertible {
    public var response: HTTPURLResponse?
    public var respData: Data = Data()
    public var decoded: Either<String, E>?
    public var errorType: RequestErrorType

    init(errorType: RequestErrorType) {
        self.errorType = errorType
    }

    init(respData: Data, errorType: RequestErrorType) {
        self.respData = respData
        self.errorType = errorType
        self.decoded = maybe_decode_error_json(respData)
    }

    public var description: String {
        if let decoded = self.decoded {
            switch decoded {
            case .left(let err):
                return err
            case .right(let err):
                return err.description
            }
        }

        let strData = String(decoding: respData, as: UTF8.self)

        guard let resp = response else {
            return "respData: \(strData)\nerrorType: \(errorType)\n"
        }

        return "response: \(resp)\nrespData: \(strData)\nerrorType: \(errorType)\n"
    }
}


func make_commando_msg<IN: Encodable>(authToken: String, operation: String, params: IN) -> Data? {
    let encoder = JSONEncoder()
    let json_data = try! encoder.encode(params)
    guard let params_json = String(data: json_data, encoding: String.Encoding.utf8) else {
        return nil
    }
    var buf = [UInt8](repeating: 0, count: 65536)
    var outlen: Int32 = 0

    authToken.withCString { token in
    operation.withCString { op in
    params_json.withCString { ps in
        outlen = commando_make_rpc_msg(op, ps, token, 1, &buf, Int32(buf.capacity))
    }}}

    guard outlen != 0 else {
        return nil
    }

    return Data(buf[..<Int(outlen)])
}


func commando_read_all(ln: LNSocket, timeout_ms: Int32 = 2000) -> RequestRes<Data> {
    var rv: Int32 = 0
    var set = fd_set()
    var timeout = timeval()

    timeout.tv_sec = __darwin_time_t(timeout_ms / 1000);
    timeout.tv_usec = (timeout_ms % 1000) * 1000;

    fd_do_zero(&set)
    let fd = ln.fd()
    fd_do_set(fd, &set)

    var all_data = Data()

    while(true) {
        rv = select(fd + 1, &set, nil, nil, &timeout)

        if rv == -1 {
            return .failure(RequestError(errorType: .selectFailed))
        } else if rv == 0 {
            return .failure(RequestError(errorType: .timeout))
        }

        guard let (msgtype, data) = ln.recv() else {
            return .failure(RequestError(errorType: .recvFailed))
        }

        if msgtype == COMMANDO_REPLY_TERM {
            all_data.append(data[8...])
            break
        } else if msgtype == COMMANDO_REPLY_CONTINUES {
            all_data.append(data[8...])
            continue
        } else if msgtype == WIRE_PING.rawValue {
            // respond to pings for long requests like waitinvoice, etc
            ln.pong(ping: data)
        } else {
            //return .failure(RequestError(errorType: .badCommandoMsgType(Int(msgtype))))
            // we could get random messages like channel update! just ignore them
            continue
        }
    }

    return .success(all_data)
}

public let default_timeout: Int32 = 8000


public func maybe_decode_error_json<T: Decodable>(_ dat: Data) -> Either<String, T>? {
    do {
        return .right(try JSONDecoder().decode(ErrorWrapper<T>.self, from: dat).error)
    } catch {
        do {
            return .left(try JSONDecoder().decode(ErrorWrapper<String>.self, from: dat).error)
        } catch {
            return nil
        }
    }
}
