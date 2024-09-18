public class D1_BuyerAccountCheck {

    @InvocableMethod
    public static List<Response> getBuyerAccountStatus(List<String> accountIds){
        
        Response res= new Response();
        res.success = true;
        
        List<Response> responseWrapper= new List<Response>();
        responseWrapper.add(res);
        return responseWrapper;
    }
    
    public class Response {
        @InvocableVariable(label='success')
        public Boolean success;
    }
}