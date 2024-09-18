/**********************************************************************
Name: EDGE_DistributorRemoveUserSharing

=======================================================================                                                       
VERSION   AUTHOR            DATE              DETAIL
1.1      Anamika Shukla     7-June-2021     ES20-10235
**************************************************************************************************************************/


public class EDGE_DistributorRemoveUserSharing implements Queueable{
    List<id> personRespList = new List<id>();
    List<String> GroupNames;
    
    
    public EDGE_DistributorRemoveUserSharing(List<id> personRespList, List<String> GroupNames){
        this.personRespList=personRespList;
        this.GroupNames=GroupNames;
    }
    
    public void execute(QueueableContext queCont) {
        
        List<UserShare> ushare= [Select id from UserShare where UserId=:personRespList AND UserOrGroup.Name IN :GroupNames];
        
        if(ushare.size()>0){
            delete ushare;
        }
        
    }
}