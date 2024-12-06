# @turbocrime/solidity-cbor

**This is a library for parsing CBOR.**

This library does not provide tools for writing CBOR.

This project was initially forked from [filecoin's CborDecode.sol](https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/utils/CborDecode.sol) by Zondax AG.

[RFC 8949](https://www.iana.org/go/rfc8949)

[CBOR Simple Values Registry](https://www.iana.org/assignments/cbor-simple-values/cbor-simple-values.xhtml)

[CBOR Tags Registry](https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml)


## Usage

Most methods accept parameters `bytes` of CBOR data and `uint32` index, and return an updated index (and one or more values if appropriate). Since the data parameter is always first, you may sugar calls via `using` directive.

CBOR natively supports values up to `uint64`, so the typical values returned are `uint64`. Some methods return other types.


Deserialization methods are a capitalized name of the type like `UInt`, `NInt`, `Text`, `Map`, and so on for every CBOR type. These return a value of the equivalent solidity type when possible.

When specific format constraints exist, some optimized method variants are available, such as `String1` when the next should be a 1-byte string.

You can peek at the type of the next item with `isBytes` and so on.

The caller is responsible for handling the index and using it to index the appropriate data. No 'cursor' metaphor is provided, but the example below demonstrates how a caller may define and use a cursor for convenience.


```solidity
using ReadCbor for bytes;

bytes constant someBytes = hex"84616103616102";

struct Cursor {
    bytes b;
    uint32 i;
}

function example() pure {
    Cursor memory c = Cursor(someBytes, 0);
    uint32 len;

    (c.i, len) = c.b.Array(c.i);

    assert(len == 4);

    string[] memory arrayStrs = new string[](len / 2);
    uint64[] memory arrayNums = new uint64[](len / 2);

    // CBOR arrays may contain items of any type.
    for (uint32 arrayIdx = 0; arrayIdx < len; arrayIdx++) {
        if (c.b.isString(c.i)) {
            (c.i, arrayStrs[arrayIdx / 2]) = c.b.String(c.i);
        } else if (c.b.isUInt(c.i)) {
            (c.i, arrayNums[arrayIdx / 2]) = c.b.UInt(c.i);
        }
    }

    c.b.requireComplete(c.i);
}
```

## Limitations

The CBOR format is very flexible and supports more types than solidity.

The caller is responsible for structure navigation and value interpretation.

### Tags

Tags must be parsed explicitly. The `Tag` method will simply return the tag value, or may be paramaterized to require a specific tag value.

### Primitives `null` and `undefined`

Solidity can't represent primitive values `null` and `undefined`.

The methods `Null` and `Undefined` will advance the index past a required value.

The methods `isNull` and `isUndefined` may be used to peek without advancing the index.

### Indefinite Length

Sequence and collection items of indefinite length are not supported.

### Collection Items

The `Array` and `Map` methods don't return fully-parsed collections, but simply return the collection size and advance the index to the first item.

Collection decoding can be quite complex, and CBOR collection types are more flexible than Solidity collection types. Since efficiency is critical in contract execution, and structures will vary widely, implementation is left up to the caller.

## Tag-specific parsers

All tagged items are valid CBOR and may be parsed manually, but [RFC 8949](https://www.rfc-editor.org/rfc/rfc8949) specifically mentions [stringref](https://cbor.schmorp.de/stringref) and [sharedref](https://cbor.schmorp.de/value-sharing) as tags which may require specialized support.

Some convenient specialized item parsers are provided in the `tags` directory.

### Tags 2 and 3: `ReadBignum`

Parses arbitrarily sized integers represented in CBOR as bytes, and returns the integer value.

Limited to `type(uint256).max` for tag 2 (positive) and `type(int256).min` for tag 3 (negative).

### Tag 42: `ReadCid`

Limited to the CID types appearing in atproto CBOR, specifically:

- DAG-CBOR SHA-256, 32 bytes
- 'raw' SHA-256, 32 bytes
