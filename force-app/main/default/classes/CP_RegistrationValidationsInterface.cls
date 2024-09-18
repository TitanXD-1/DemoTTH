/**************************************************************************************
Apex Class Name  :  CP_RegistrationValidationsInterface 
Version          :  1.0
Created Date     :  14/08/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock         14/08/2019             Original Version
******************************************************************************/
public interface CP_RegistrationValidationsInterface{
	Map<Id,String> execute(Map<Id,Account> mapAccounts); 
}