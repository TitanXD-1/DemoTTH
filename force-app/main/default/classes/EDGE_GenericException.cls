/**********************************************************************
Name: EDGE_GenericException
=======================================================================
Req: 

=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh	10/05/2019		  Initial Development
***********************************************************************/
public class EDGE_GenericException extends Exception {  
    
    public EDGE_GenericException(Exception excption, SObject errorObject){
        if(errorObject != null){
            errorObject.addError(Label.Generic_Exception_Message+' '+excption.getMessage()+ ' .Line Number: '+excption.getLineNumber());
        }        
    }
    
}