/**
 * SampleApexClass
 *
 * Demonstrates a simple, bulk-friendly, and LWC-ready Apex utility.
 * - inherited sharing: respects the caller’s sharing context
 * - No SOQL/DML to keep it self-contained
 * - Includes an @AuraEnabled cacheable method for LWC usage
 *
 * Usage:
 *   String msg = SampleApexClass.greet('Aman'); // "Hello, Aman"
 *   String msg2 = SampleApexClass.greet(null);  // "Hello, World"
 */
public inherited sharing class SampleApexClass {

    /**
     * Returns a friendly greeting.
     * Null/blank names default to "World".
     */
    public static String greet(String name) {
        String safe = String.isBlank(name) ? 'World' : name.trim();
        return 'Hello, ' + safe;
    }

    /**
     * LWC-friendly greeting method.
     * Marked cacheable as it is pure and has no side effects.
     */
    @AuraEnabled(cacheable=true)
    public static String greetForLwc(String name) {
        return greet(name);
    }

    /**
     * Example bulk-friendly method that formats greetings for many names.
     * Accepts a List and returns a List (no DML/SOQL).
     */
    public static List<String> greetMany(List<String> names) {
        List<String> out = new List<String>();
        if (names == null) {
            return out;
        }
        for (String n : names) {
            out.add(greet(n));
        }
        return out;
    }
}