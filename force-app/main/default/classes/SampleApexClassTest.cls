@IsTest
private class SampleApexClassTest {

    @IsTest
    static void testGreet_withName() {
        String res = SampleApexClass.greet('Aman');
        System.assertEquals('Hello, Aman', res);
    }

    @IsTest
    static void testGreet_nullOrBlank() {
        System.assertEquals('Hello, World', SampleApexClass.greet(null));
        System.assertEquals('Hello, World', SampleApexClass.greet(''));
        System.assertEquals('Hello, World', SampleApexClass.greet('   '));
    }

    @IsTest
    static void testGreetMany_bulk() {
        List<String> input = new List<String>{ 'Ada', null, '  Ben  ' };
        List<String> res = SampleApexClass.greetMany(input);
        System.assertEquals(3, res.size());
        System.assertEquals('Hello, Ada', res[0]);
        System.assertEquals('Hello, World', res[1]);
        System.assertEquals('Hello, Ben', res[2]);
    }

    @IsTest
    static void testGreetForLwc() {
        String res = SampleApexClass.greetForLwc('LWC');
        System.assertEquals('Hello, LWC', res);
    }
}