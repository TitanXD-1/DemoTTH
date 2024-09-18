public class MD_GeneralFormWrapper {
    
	public class FormSettings {
        
        public String saveClass;
        public String retrievalClass;
        public String styleClass;
        public String uniqueFormName;
        public List<MD_GeneralFormWrapper.Section> sections;

        public FormSettings(DiageoCMS.GeneralForm.FormSettings formSettings){
            this.styleClass = formSettings.styleClass;
            this.uniqueFormName = formSettings.uniqueFormName;
            this.sections = this.sectionsMapper(formSettings.sections);
            this.retrievalClass = formSettings.retrievalClass;
            this.saveClass = formSettings.saveClass;
        }
        
        public List<MD_GeneralFormWrapper.Section> sectionsMapper(List<DiageoCMS.GeneralForm.Section> formSections) {
            List<MD_GeneralFormWrapper.Section> result = new List<MD_GeneralFormWrapper.Section>();

            for(DiageoCMS.GeneralForm.Section formSection : formSections) {
                result.add(new MD_GeneralFormWrapper.Section(formSection));
            }

            return result;
        }
    }
    
    public class Section {
        public String SectionTitle;
        public String styleClass;
        public Integer order;
        public List<MD_GeneralFormWrapper.Element> fields;
        public String sectionWidth;
        
        public Section(DiageoCMS.GeneralForm.Section formSection){
            List<MD_GeneralFormWrapper.Element> elements = new List<MD_GeneralFormWrapper.Element>();

            this.sectionTitle = formSection.sectionTitle;
            this.styleClass = formSection.styleClass;
            this.order = formSection.order;
            this.sectionWidth = formSection.sectionWidth;

            for(DiageoCMS.GeneralForm.Element ele : formSection.fields) {
                elements.add(new MD_GeneralFormWrapper.Element(ele));
            }

            this.fields = elements;
        }
    }

    public class Element {
        public String objApiName;
        public String apiName;
        public String displayType;
        public String label;
        public String placeHolder;
        public String helpText;
        public Boolean isRequired;
        public Boolean readOnly;
        public String defaultValue;
        public String styleClass;
        public List<String> picklistValues;
        public Boolean hasValidation;
        public String validationErrorMessage;
        public String validationRegExp;
        public String fieldMask;
        public Integer maxLength;
        public Boolean hasConfirmation;
        public String confirmationLabel;
        public String confirmationPlaceholder;
        public String confirmationErrMessage;
        public Integer textAreaRows;
        
        public Element(DiageoCMS.GeneralForm.Element field) {
            this.objApiName = field.objApiName;
            this.apiName = field.apiName;
            this.displayType = field.displayType;
            this.textAreaRows = field.textAreaRows;
            this.label = field.label;
            this.placeHolder = field.placeHolder;
            this.helpText = field.helpText;
            this.isRequired = field.isRequired;
            this.readOnly = field.readOnly;
            this.defaultValue = field.defaultValue;
            this.styleClass = field.styleClass;
            this.picklistValues = field.picklistValues;
            this.hasValidation = field.hasValidation;
            this.validationErrorMessage = field.validationErrorMessage;
            this.validationRegExp = field.validationRegExp;
            this.maxLength = field.maxLength;
            this.hasConfirmation = field.hasConfirmation;
            this.confirmationLabel = field.confirmationLabel;
            this.confirmationPlaceholder = field.confirmationPlaceholder;
            this.confirmationErrMessage = field.confirmationErrMessage;
        }
    }
}