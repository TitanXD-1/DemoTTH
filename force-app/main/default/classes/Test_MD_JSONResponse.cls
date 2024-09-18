/**
* @Author: Cloudgaia. (Julia Carranza)
* @Description: Test the MD_JSONResponse Class.
*/

@isTest
public class Test_MD_JSONResponse {

    static testMethod void myTestMethod() {
        MD_JSONResponse newJSON1 = new MD_JSONResponse();
        MD_JSONResponse newJSON2 = new MD_JSONResponse(true, 'message');
        MD_JSONResponse newJSON3 = new MD_JSONResponse(true, 'message', MD_JSONResponse.MD_JSONResponseType.WARNING);
        MD_JSONResponse newJSON4 = new MD_JSONResponse(true, 'message', MD_JSONResponse.MD_JSONResponseType.WARNING, 'title');
    }
}