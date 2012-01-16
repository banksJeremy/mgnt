//&>/dev/null;x="${0%.*}";[ ! "$x" -ot "$0" ]||(rm -f "$x";cc --std=c99 -Wall -o "$x" "$0")&&exec "$x" "$@"
#import <stdint.h>
#import <stdio.h> 
#import <time.h>
#import <stdlib.h>
#import <inttypes.h>

uint8_t rand_u8() {
    return (uint8_t) (0xFF & rand());
}

uint16_t rand_u16() {
    return (((uint16_t) rand_u8()) << 8) + ((uint16_t) rand_u8());
}

uint32_t rand_u32() {
    return (((uint32_t) rand_u16()) << 16) + ((uint32_t) rand_u16());
}

uint64_t rand_u64() {
    return (((uint64_t) rand_u32()) << 32) + ((uint64_t) rand_u32());
}

#define DESCRIBE_TEST(bitsize, method, operator) \
    puts("describe('" #bitsize "-bit ." #method "', function() {"); \
    uint ## bitsize ##_t ls$ ## bitsize ## method, rs$ ## bitsize ## method; \
    for (int i = 0; i <= limit; i++) { \
        if (i == 0) ls$ ## bitsize ## method = 0; \
        else if (i == limit) ls$ ## bitsize ## method = ((uint ## bitsize ## _t) 0) - 1; \
        else ls$ ## bitsize ## method = rand_u ## bitsize (); \
        for (int j = 0; j <= limit; j++) { \
            if (j == 0) rs$ ## bitsize ## method = 0; \
            else if (j == limit) rs$ ## bitsize ## method = ((uint ## bitsize ## _t) 0) - 1; \
            else rs$ ## bitsize ## method = rand_u ## bitsize (); \
            printf("expect(Bytes.fromHex('%" PRIx ## bitsize "', " #bitsize "/8)" \
                   "." #method "(Bytes.fromHex('%" PRIx ## bitsize "', " #bitsize "/8)))\n" \
                   ".toEqual(Bytes.fromHex('%" PRIx ## bitsize "', " #bitsize "/8));\n", \
                   ls$ ## bitsize ## method, rs$ ## bitsize ## method, \
                   ls$ ## bitsize ## method operator rs$ ## bitsize ## method); \
        } \
    } \
    puts("});");

#define DESCRIBE_TEST_FOR_SIZE(bitsize) \
    DESCRIBE_TEST(bitsize, add, +) \
    DESCRIBE_TEST(bitsize, and, &) \
    DESCRIBE_TEST(bitsize, or, |) \
    DESCRIBE_TEST(bitsize, xor, ^)

int main() {
    srand(74526);
    
    puts("describe('mgnt.base', function() {");
    puts("describe('Bytes', function() {var Bytes = mgnt.Bytes;");
    puts("describe('(generated tests)', function() {");
    
    int limit = 4;
    
    DESCRIBE_TEST_FOR_SIZE(8)
    DESCRIBE_TEST_FOR_SIZE(16)
    DESCRIBE_TEST_FOR_SIZE(32)
    DESCRIBE_TEST_FOR_SIZE(64)
    
    puts("});});});");

    return 0;
}
