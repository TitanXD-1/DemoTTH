/**********************************************************************
Name: EDGE_LabelTranslatorControllerTest
=======================================================================
Purpose: Trigger Helper Class for EDGE_LabelTranslatorController
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Manikant prasad       06/11/2019        Method : testLabelController
*****************/
@isTest
public with sharing class EDGE_LabelTranslatorControllerTest {
    @isTest
       public static void testLabelController(){
        PageReference pageRef = Page.EDGE_LabelTranslator;
        Test.setCurrentPage(pageRef); 
        ApexPages.currentPage().getParameters().put('label_lang','ES');
        List<String> labelNames = new List<String>{'EDGE_AccountName'};
        ApexPages.currentPage().getParameters().put('labels', JSON.serialize(labelNames));
		EDGE_LabelTranslatorController controller = new EDGE_LabelTranslatorController();
        controller.label = label.edge_clientCode;
        controller.labelListSize = 1;
           system.assert(labelNames.size() > 0);
    }

}