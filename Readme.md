
# Plasma

Plasma acts like a lightning node to issue commands directly to your node over the lightning network. Thanks to [@jb55](https://github.com/jb55)
for developing [LNSocket](https://github.com/jb55/lnsocket) which makes this possible. For more information about LNSocket check out this [video](https://www.youtube.com/watch?v=LZLRCPNn7vA).

⚠️ Plasma is in beta!

## Features
- LNSocket/LNLink for connectiong to your node
- Bolt12 send/receive
- Bolt11 send/receive
- Taproot addresses for onchain deposits
- Onchain send and receive
- Payment history
- Onchain UTXOs
- Add channels
- Rebalance channels

Todo:
- Bypass the onchain wallet with psbt's when creating channels.
- Coin control when spending from onchain wallet.
- Fee settings for onchain wallet.


## Build Plasma from source
<br/><img src="./Images/build_from_source.png" alt="" width="400"/><br/>
* Download Xcode
* `git clone https://github.com/Fonta1n3/Plasma.git`
* `cd Plasma`
* Double click `Plasma.xcodeproj`
* Click the play button in the top left bar of Xcode to run the app.


## Connecting your node
Plasma supports a format called [LNLink](https://lnlink.app/qr/) developed by [@jb55](https://github.com/jb55).

To connect your node, navigate to "Settings" > "Node Manager" > + .

You may either use the script provided at [LNLink](https://lnlink.app/qr/) or you can enter the credentials manually.

On your Core Lightning node:
`lightning-cli getinfo`
 
 Which should return something like this:
 ```
 {
  "id" : "029ef4031f9c8598d0551ca3635d9219233b907ffb63979f9952658bb38b0ec3ae",
  "network" : "regtest",
  "color" : "029ef4",
  "num_inactive_channels" : 0,
  "our_features" : {
    "node" : "88a0800a0269a2",
    "channel" : "",
    "invoice" : "02000002024100",
    "init" : "08a0800a0269a2"
  },
  "version" : "v23.08.1",
  "binding" : [
    {
      "type" : "ipv4",
      "address" : "0.0.0.0",
      "port" : 7171
    }
  ],
  "num_pending_channels" : 0,
  "fees_collected_msat" : 0,
  "blockheight" : 146,
  "alias" : "SLICKERGENESIS",
  "address" : [
    {
      "type" : "ipv4",
      "address" : "127.0.0.1",
      "port" : 7171
    }
  ],
  "num_peers" : 3,
  "lightning-dir" : "\/tmp\/l1-regtest\/regtest",
  "num_active_channels" : 1
}
 ```
 
 Add the node ID, the address, and the port to Plasma.
 
 You will then need to generate a [rune](https://docs.corelightning.org/reference/lightning-commando-rune).
 
 Do this with:
 `lightning-cli commando-rune`
 
 Which will return:
 ```
 {
   "rune": "0f23-l0ppAipYBq7gDf77T6XDNwWlY2qWKle_2S8yYE9MQ==",
   "unique_id": "1",
   "warning_unrestricted_rune": "WARNING: This rune has no restrictions! Anyone who has access to this rune could drain funds from your node. Be careful when giving this to apps that you don't trust. Consider using the restrictions parameter to only allow access to specific rpc methods."
}
 ```
 
Paste the rune `0f23-l0ppAipYBq7gDf77T6XDNwWlY2qWKle_2S8yYE9MQ==`, tap "Save", navigate back to the home screen and tap the refresh button.
 
You can add all sorts of restrictions to runes to limit the functionality of Plasma, share your node and a restricted 
rune with others so they can easily pay you by generating invoices from your node directly!


## Cost

### Redistributing Plasma Code on the App Store

Even though this project is open source, this does not mean you can reuse this code when distributing closed source commercial products. Please [contact us](mailto:dentondevelopment@protonmail.com) to discuss licensing options before you start building your product.

If you are an open source project, please [contact us](mailto:dentondevelopment@protonmail.com) to arrange for an App Store redistribution exception. For more information about why this is required, please read [this blog post](https://whispersystems.org/blog/license-update/) from Open Whisper Systems.


### Cost for End Users

Downloading the Plasma iOS app is **free** because it is important that all people around the world have unrestricted access to a private, self sovereign means of using Bitcoin.
However, developing and supporting this project is hard work and costs real money. Please help support the development of this project!

* [GitHub Sponsors](https://github.com/sponsors/fonta1n3)


## PGP

* 1C72 2776 3647 A221 6E02 E539 025E 9AD2 D3AC 0FCA


## License

MIT
"Commons Clause" License Condition v1.0

If you would like to relicense this code to distribute it on the App Store,
please contact me at [dentondevelopment@protonmail.com](mailto:dentondevelopment@protonmail.com).



