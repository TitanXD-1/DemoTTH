public with sharing class D1_UserUpdateQueueable implements Queueable{

    public List<User> userList;
        
    public D1_UserUpdateQueueable(List<User> userList){
        
        this.userList = userList;
    }

    public void execute(QueueableContext context) {
        
        if(!userList.isEmpty()){
            update userList;
        }       
        
    }
    
}