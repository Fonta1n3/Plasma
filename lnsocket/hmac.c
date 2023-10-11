/* Copyright Rusty Russell (Blockstream) 2015.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include <string.h>
#include "hmac.h"

#define IPAD 0x3636363636363636ULL
#define OPAD 0x5C5C5C5C5C5C5C5CULL

#define BLOCK_256_U64S (HMAC_SHA256_BLOCKSIZE / sizeof(uint64_t))
#define BLOCK_512_U64S (HMAC_SHA512_BLOCKSIZE / sizeof(uint64_t))

static inline void xor_block_256(uint64_t block[BLOCK_256_U64S], uint64_t pad)
{
	size_t i;

	for (i = 0; i < BLOCK_256_U64S; i++)
		block[i] ^= pad;
}


static inline void xor_block_512(uint64_t block[BLOCK_512_U64S], uint64_t pad)
{
	size_t i;

	for (i = 0; i < BLOCK_512_U64S; i++)
		block[i] ^= pad;
}

void hmac_sha256_init(struct hmac_sha256_ctx *ctx,
		      const void *k, size_t ksize)
{
	struct sha256 hashed_key;
	/* We use k_opad as k_ipad temporarily. */
	uint64_t *k_ipad = ctx->k_opad;

	/* (keys longer than B bytes are first hashed using H) */
	if (ksize > HMAC_SHA256_BLOCKSIZE) {
		sha256(&hashed_key, k, ksize);
		k = &hashed_key;
		ksize = sizeof(hashed_key);
	}

	/* From RFC2104:
	 *
	 * (1) append zeros to the end of K to create a B byte string
	 *  (e.g., if K is of length 20 bytes and B=64, then K will be
	 *   appended with 44 zero bytes 0x00)
	 */
	memcpy(k_ipad, k, ksize);
	memset((char *)k_ipad + ksize, 0, HMAC_SHA256_BLOCKSIZE - ksize);

	/*
	 * (2) XOR (bitwise exclusive-OR) the B byte string computed
	 * in step (1) with ipad
	 */
	xor_block_256(k_ipad, IPAD);

	/*
	 * We start (4) here, appending text later:
	 *
	 * (3) append the stream of data 'text' to the B byte string resulting
	 * from step (2)
	 * (4) apply H to the stream generated in step (3)
	 */
	sha256_init(&ctx->sha);
	sha256_update(&ctx->sha, k_ipad, HMAC_SHA256_BLOCKSIZE);

	/*
	 * (5) XOR (bitwise exclusive-OR) the B byte string computed in
	 * step (1) with opad
	 */
	xor_block_256(ctx->k_opad, IPAD^OPAD);
}


void hmac_sha512_init(struct hmac_sha512_ctx *ctx,
		      const void *k, size_t ksize)
{
	struct sha512 hashed_key;
	/* We use k_opad as k_ipad temporarily. */
	uint64_t *k_ipad = ctx->k_opad;

	/* (keys longer than B bytes are first hashed using H) */
	if (ksize > HMAC_SHA512_BLOCKSIZE) {
		sha512(&hashed_key, k, ksize);
		k = &hashed_key;
		ksize = sizeof(hashed_key);
	}

	/* From RFC2104:
	 *
	 * (1) append zeros to the end of K to create a B byte string
	 *  (e.g., if K is of length 20 bytes and B=64, then K will be
	 *   appended with 44 zero bytes 0x00)
	 */
	memcpy(k_ipad, k, ksize);
	memset((char *)k_ipad + ksize, 0, HMAC_SHA512_BLOCKSIZE - ksize);

	/*
	 * (2) XOR (bitwise exclusive-OR) the B byte string computed
	 * in step (1) with ipad
	 */
	xor_block_512(k_ipad, IPAD);

	/*
	 * We start (4) here, appending text later:
	 *
	 * (3) append the stream of data 'text' to the B byte string resulting
	 * from step (2)
	 * (4) apply H to the stream generated in step (3)
	 */
	sha512_init(&ctx->sha);
	sha512_update(&ctx->sha, k_ipad, HMAC_SHA512_BLOCKSIZE);

	/*
	 * (5) XOR (bitwise exclusive-OR) the B byte string computed in
	 * step (1) with opad
	 */
	xor_block_512(ctx->k_opad, IPAD^OPAD);
}


void hmac_sha256_update(struct hmac_sha256_ctx *ctx, const void *p, size_t size)
{
	/* This is the appending-text part of this:
	 *
	 * (3) append the stream of data 'text' to the B byte string resulting
	 * from step (2)
	 * (4) apply H to the stream generated in step (3)
	 */
	sha256_update(&ctx->sha, p, size);
}


void hmac_sha512_update(struct hmac_sha512_ctx *ctx, const void *p, size_t size)
{
	sha512_update(&ctx->sha, p, size);
}


void hmac_sha256_done(struct hmac_sha256_ctx *ctx,
		      struct hmac_sha256 *hmac)
{
	/* (4) apply H to the stream generated in step (3) */
	sha256_done(&ctx->sha, &hmac->sha);

	/*
	 * (6) append the H result from step (4) to the B byte string
	 * resulting from step (5)
	 * (7) apply H to the stream generated in step (6) and output
	 * the result
	 */
	sha256_init(&ctx->sha);
	sha256_update(&ctx->sha, ctx->k_opad, sizeof(ctx->k_opad));
	sha256_update(&ctx->sha, &hmac->sha, sizeof(hmac->sha));
	sha256_done(&ctx->sha, &hmac->sha);
}


void hmac_sha512_done(struct hmac_sha512_ctx *ctx,
		      struct hmac_sha512 *hmac)
{
	/* (4) apply H to the stream generated in step (3) */
	sha512_done(&ctx->sha, &hmac->sha);

	/*
	 * (6) append the H result from step (4) to the B byte string
	 * resulting from step (5)
	 * (7) apply H to the stream generated in step (6) and output
	 * the result
	 */
	sha512_init(&ctx->sha);
	sha512_update(&ctx->sha, ctx->k_opad, sizeof(ctx->k_opad));
	sha512_update(&ctx->sha, &hmac->sha, sizeof(hmac->sha));
	sha512_done(&ctx->sha, &hmac->sha);
}

#if 1
void hmac_sha256(struct hmac_sha256 *hmac,
		 const void *k, size_t ksize,
		 const void *d, size_t dsize)
{
	struct hmac_sha256_ctx ctx;

	hmac_sha256_init(&ctx, k, ksize);
	hmac_sha256_update(&ctx, d, dsize);
	hmac_sha256_done(&ctx, hmac);
}


void hmac_sha512(struct hmac_sha512 *hmac,
		 const void *k, size_t ksize,
		 const void *d, size_t dsize)
{
	struct hmac_sha512_ctx ctx;

	hmac_sha512_init(&ctx, k, ksize);
	hmac_sha512_update(&ctx, d, dsize);
	hmac_sha512_done(&ctx, hmac);
}


#else
/* Direct mapping from MD5 example in RFC2104 */
void hmac_sha256(struct hmac_sha256 *hmac,
		 const void *key, size_t key_len,
		 const void *text, size_t text_len)
{
	struct sha256_ctx context;
        unsigned char k_ipad[65];    /* inner padding -
                                      * key XORd with ipad
                                      */
        unsigned char k_opad[65];    /* outer padding -
                                      * key XORd with opad
                                      *//* start out by storing key in pads */
	unsigned char tk[32];
        int i;

        /* if key is longer than 64 bytes reset it to key=MD5(key) */
        if (key_len > 64) {

                struct sha256_ctx      tctx;

                sha256_init(&tctx);
                sha256_update(&tctx, key, key_len);
                sha256_done(&tctx, tk);

                key = tk;
                key_len = 32;
        }
        bzero( k_ipad, sizeof k_ipad);
        bzero( k_opad, sizeof k_opad);
        bcopy( key, k_ipad, key_len);
        bcopy( key, k_opad, key_len);

        /* XOR key with ipad and opad values */
        for (i=0; i<64; i++) {
                k_ipad[i] ^= 0x36;
                k_opad[i] ^= 0x5c;
        }
        /*
         * perform inner MD5
         */
        sha256_init(&context);                   /* init context for 1st
                                              * pass */
        sha256_update(&context, k_ipad, 64);      /* start with inner pad */
        sha256_update(&context, text, text_len); /* then text of datagram */
        sha256_done(&context, &hmac->sha);          /* finish up 1st pass */
        /*
         * perform outer MD5
         */
        sha256_init(&context);                   /* init context for 2nd
                                              * pass */
        sha256_update(&context, k_opad, 64);     /* start with outer pad */
        sha256_update(&context, &hmac->sha, 32);     /* then results of 1st
                                              * hash */
        sha256_done(&context, &hmac->sha);          /* finish up 2nd pass */
}
#endif
