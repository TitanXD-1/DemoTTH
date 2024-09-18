/**
 * Created by Cloudgaia on 09/05/2018. 
 */

public virtual with sharing class MD_JSONResponse {
    public enum MD_JSONResponseType { SUCCESS, WARNING, ERROR, INFO, OTHER }

    public Boolean status {get;set;}
    public String title {get;set;}
    public MD_JSONResponse.MD_JSONResponseType type {get;set;}
    public String message {get;set;}

    public MD_JSONResponse() {
        this.status = false;
        this.message = '';
        this.type = MD_JSONResponse.MD_JSONResponseType.INFO;
        this.title = '';
    }

    public MD_JSONResponse(Boolean status, String message) {
        this.status = status;
        this.message = message;
        this.type = MD_JSONResponse.MD_JSONResponseType.INFO;
        this.title = '';
    }

    public MD_JSONResponse(Boolean status, String message, MD_JSONResponse.MD_JSONResponseType type) {
        this.status = status;
        this.message = message;
        this.type = type;
        this.title = '';
    }

    public MD_JSONResponse(Boolean status, String message, MD_JSONResponse.MD_JSONResponseType type, String title) {
        this.status = status;
        this.message = message;
        this.type = type;
        this.title = title;
    }
}