/**
 * @description Base abstract class for all API services
 * @author PAVANSAI KODANDA
 * @version 1.0
 * @date 2024-12-23
 */
public abstract class BaseAPIService {
    protected final APIService apiService;
    protected String apiEndpoint;
    protected String namedCredential;
    
    /**
     * @description Constructor initializing the API service with endpoint
     * @param endpoint The API endpoint to be used for service calls
     */
    public BaseAPIService(String endpoint) {
        this.apiService = new APIService();
        this.apiEndpoint = endpoint;
    }
    public BaseAPIService(){
        this.apiService = new APIService();
    }
    /**
     * @description Sets the API endpoint for the service
     * @param endpoint The API endpoint to be set
     */
    public void setApiEndpoint(String endpoint) {
        this.apiEndpoint = endpoint;
    }
    /**
     * @description Sets the API endpoint for the service
     * @param endpoint The API endpoint to be set
     */
    public void setNamedCredential(String namedCredential) {
        this.namedCredential = namedCredential;
    }
}