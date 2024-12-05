# solidity-bsky-cbor

**solidity-bsky-cbor is a library for parsing and verifying record inclusion in atproto repositories.**

The basic CBOR decoding is forked from [the filecoin CBOR code](https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/utils/CborDecode.sol) by Zondax AG.

The atproto features were developed by reference the [atproto data model](https://atproto.com/specs/data-model).

## Usage

This library is designed for use with off-chain software which selects appropriate records and formats contract calldata.

Your contract should know a trusted pubkey, and track the last seen repo revision to prevent replay.

### off-chain

You identify a new record of interest.

1. know the actor `did`, namespaced `collection`, and `rkey` identifying the record of interest
1. query the appropriate PDS with `com.atproto.sync.getRecord` to obtain the proving MST
2. parse the response `application/vnd.ipld.car` and separate:
   - the MST node CBORs
   - the record CBOR
   - the unsigned commit CBOR
   - the commit signature `r` and `s` components

Call your contract.

### on-chain

Your established contract is called.

4. knowing a previous repo revision, parse the commit with `verifyCommit`. a root CID and new revision return.
5. knowing the record key and the root CID, parse the MST with `verifyInclusion`. a value CID returns.
6. knowing the record content and the value CID, confirm the value CID refers to the record content.
7. the record is proven. store the new revision.

Your contract may now proceed to parse and act on the authenticated record.

### Example

Contract use of this library might look like this:

```sol
function exampleUse(
    bytes calldata commitCbor,
    bytes calldata recordCbor,
    bytes[] calldata mstCbors,
    bytes32 sig_r,
    bytes32 sig_s,
    string calldata recordKey,
) external {
    Commit memory commit = commitCbor.verifyCommit(sig_r, sig_s, trustedSigner, lastRev);
    Tree memory mst = mstCbors.readTree();
    Cid valueCid = mst.verifyInclusion(commit.data, recordKey);
    require(valueCid.isFor(recordCbor), "Key identifies a different record");

    lastRev = commit.rev;
    exampleAction(recordCbor);
}
```

## Record parsing

~~A few record parsing utilities are provided for some common bluesky lexicons.~~

A single record parsing utility is provided for Bluesky posts.

- `app.bsky.feed.post`
- `app.bsky.feed.like`
- `app.bsky.feed.repost`
- ~~`app.bsky.graph.block`~~
- ~~`app.bsky.graph.follow`~~
- ~~`app.bsky.richText.facet`~~

Otherwise, you are responsible for implementing your own record parsing.
