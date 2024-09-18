/*
 * @class: CO_BatchResendToSAPSchedular
 * @description: This is the Scheduler class for CO_BatchResendToSAP
 * @History                                                                                                                       
 * @VERSION      AUTHOR             DATE              DETAIL
   1.0           Cons Dev Team      11-25-2022        Initial Development
 * */
public with sharing class CO_BatchResendToSAPSchedular implements Schedulable {
	public void execute(SchedulableContext sc){
        CO_BatchResendToSAP resendToSAP = new CO_BatchResendToSAP();
        Database.executeBatch(resendToSAP,5);
    }
}