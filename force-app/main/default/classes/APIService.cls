/**
 * @description Service for making HTTP callouts using Named Credentials
 * @author Amit Kumar
 * @version 1.0
 * @date 2024-12-23
 */
public with sharing class APIService {
    private static final String UTF8_ENCODING = 'UTF-8';
    private static final String CONTENT_TYPE = 'Content-Type';
    private static final Integer DEFAULT_TIMEOUT = 120000;
    
    /**
     * @description Makes an HTTP callout using Named Credentials
     * @param endpoint The API endpoint path (will be appended to Named Credential URL)
     * @param method HTTP method (GET, POST, etc.)
     * @param body Request body (optional)
     * @param headers Map of header key-value pairs
     * @param timeout Request timeout in milliseconds
     * @param setCompressed Whether to compress the request
     * @return HttpResponse The response from the API
     * @throws APIServiceException If the callout fails or validation fails
     */
    public HttpResponse makeCallout(
        String endpoint,
        String method,
        String body,
        Map<String, String> headers,
        Integer timeout,
        Boolean setCompressed
    ) {
        try {
            validateInput(endpoint, method);
            HttpRequest req = buildRequest(endpoint, method, body, headers, timeout, setCompressed);
            return sendRequest(req);
        } catch(Exception ex) {
            throw new APIServiceException(ex.getMessage());
        }
    }
    
    /**
     * @description Overloaded method with default values for simpler callouts
     * @param endpoint The API endpoint path
     * @param method HTTP method
     * @param body Request body
     * @return HttpResponse The response from the API
     * @throws APIServiceException If the callout fails
     */
    public HttpResponse makeCallout(String endpoint, String method, String body) {
        return makeCallout(
            endpoint,
            method,
            body,
            new Map<String, String>(),
            DEFAULT_TIMEOUT,
            true
        );
    }
    
    /**
     * @description Validates the required input parameters
     * @param endpoint The API endpoint to validate
     * @param method The HTTP method to validate
     * @throws APIServiceException If validation fails
     */
    private void validateInput(String endpoint, String method) {
        if (String.isBlank(endpoint)) {
            throw new APIServiceException('Endpoint cannot be blank');
        }
        if (String.isBlank(method)) {
            throw new APIServiceException('Method cannot be blank');
        }
    }
    
    /**
     * @description Builds the HTTP request with all parameters
     * @param endpoint The API endpoint
     * @param method HTTP method
     * @param body Request body
     * @param headers Map of headers
     * @param timeout Request timeout
     * @param setCompressed Whether to compress
     * @return HttpRequest The configured request
     */
    private HttpRequest buildRequest(
        String endpoint,
        String method,
        String body,
        Map<String, String> headers,
        Integer timeout,
        Boolean setCompressed
    ) {
        HttpRequest req = new HttpRequest();
        String fullEndpoint = endpoint;
        
        req.setEndpoint(fullEndpoint);
        req.setMethod(method);
        
        if (String.isNotBlank(body)) {
            req.setBody(body);
        }
        
        req.setTimeout(timeout != null ? timeout : DEFAULT_TIMEOUT);
        req.setCompressed(setCompressed == null ? true : setCompressed);
        
        if (headers != null) {
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }
        
        return req;
    }
    
    /**
     * @description Sends the HTTP request
     * @param request The prepared HttpRequest
     * @return HttpResponse The response from the server
     */
    private HttpResponse sendRequest(HttpRequest request) {
        Http http = new Http();
        system.debug('request'+request.getBody());
        HttpResponse Response  = http.send(request);
        system.debug('response'+response.getBody());
        return Response;
    }
    
    public class APIServiceException extends Exception {}
}