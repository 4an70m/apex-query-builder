/**
 * Created by User on 18.03.2018.
 */

public with sharing class QueryBuilder {

    private String fromSobject;
    private Set<String> fieldTokens;
    private ConditionsManager conditionsManager;
    private PostQueryUpdater postQueryUpdater;
    private Integer queryLimit;
    private Integer countResult;

    private List<SObject> result;
    private List<Order> sortingOrder;

    public QueryBuilder() {
        this.fieldTokens = new Set<String>();
        this.sortingOrder = new List<Order>();
        this.conditionsManager = new ConditionsManager(this);
        this.postQueryUpdater = new postQueryUpdater(this);
        this.queryLimit = 0;
        this.countResult = null;
    }

    public QueryBuilder(String fromSobject) {
        this();
        this.fromSobject = fromSobject.trim();
    }

    public QueryBuilder(SObjectType type) {
        this();
        this.fromSobject = type.getDescribe().getName();
    }

    public QueryBuilder(Type type) {
        this();
        this.fromSobject = type.getName();
    }

    public QueryBuilder(SObject sobj) {
        this(sobj.getSObjectType());
    }

    public QueryBuilder(List<SObject> resultList) {
        this();
        this.result = resultList;
        if (this.result.isEmpty()) {
            return;
        }
        SObject firstSobj = this.result[0];
        this.qbFrom(firstSobj);
        this.qbFields(firstSobj);
    }

    //from
    public QueryBuilder qbFrom(String sobjName) {
        this.fromSobject = sobjName.trim();
        return this;
    }

    public QueryBuilder qbFrom(SObjectType type) {
        String sobjectName = type.getDescribe().getName();
        return this.qbFrom(sobjectName);
    }

    public QueryBuilder qbFrom(Type type) {
        this.fromSobject = type.getName();
        return this;
    }

    public QueryBuilder qbFrom(SObject sobj) {
        String sobjectName = sobj.getSObjectType().getDescribe().getName();
        return this.qbFrom(sobjectName);
    }

    public QueryBuilder qbSubQuery(QueryBuilder queryBuilder) {
        return this.qbField('(' + queryBuilder.toString() + ')');
    }

    public QueryBuilder qbSubQuery(String query) {
        return this.qbField('(' + query + ')');
    }

    //fields
    public QueryBuilder qbField(String fieldName) {
        if (fieldName.contains(',')) {
            return this.qbFields(fieldName);
        }
        this.fieldTokens.add(fieldName.trim());
        return this;
    }

    public QueryBuilder qbField(SObjectField field) {
        this.fieldTokens.add(field.getDescribe().getName());
        return this;
    }

    public QueryBuilder qbFields(SObject sobj) {
        Map<String, Object> populatedFields = sobj.getPopulatedFieldsAsMap();
        for (String field : populatedFields.keySet()) {
            this.fieldTokens.add(field);
        }
        return this;
    }

    public QueryBuilder qbFields(String fieldNames) {
        List<String> fields  = fieldNames.trim().split(',');
        for (String field : fields) {
            this.fieldTokens.add(field.trim());
        }
        return this;
    }

    public QueryBuilder qbFields(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.fieldTokens.add(fieldName.trim());
        }
        return this;
    }

    public QueryBuilder qbFields(Set<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.fieldTokens.add(fieldName.trim());
        }
        return this;
    }

    //all fields
    public QueryBuilder qbFieldsAll() {
        return this.qbFieldsAll(this.fromSobject);
    }

    public QueryBuilder qbFieldsAll(String sobjectName) {
        Set<String> fieldNames = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap().keySet();
        this.fieldTokens.addAll(fieldNames);
        return this;
    }

    public QueryBuilder qbFieldsAll(Type sobjectType) {
        return this.qbFieldsAll(sobjectType.toString());
    }

    public QueryBuilder qbAllCreatableFields() {
        return this.qbAllCreatableFields(this.fromSobject);
    }

    public QueryBuilder qbAllCreatableFields(String sobjectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        Set<String> createableFields = new Set<String>{};
        for (Schema.SObjectField field : fieldMap.values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCreateable()) {
                createableFields.add(fieldDescribe.getName());
            }
        }
        fieldTokens.addAll(createableFields);
        return this;
    }

    public QueryBuilder qbAllCreatableFields(Type sobjectType) {
        return this.qbAllCreatableFields(sobjectType.toString());
    }

    //field sets
    public QueryBuilder qbFieldSet(String objectName, String fieldSetName) {
        Set<String> result = new Set<String>();
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = GlobalDescribeMap.get(objectName);
        List<FieldSetMember> fields = sObjectTypeObj.getDescribe().FieldSets.getMap().get(fieldSetName).getFields();
        for (FieldSetMember fieldSetMember : fields) {
            result.add(fieldSetMember.getFieldPath());
        }
        this.fieldTokens.addAll(result);
        return this;
    }

    public QueryBuilder qbFieldSet(FieldSet fieldSet) {
        Set<String> fieldNames = new Set<String>();
        for (FieldSetMember fieldSetMember : fieldSet.getFields()) {
            fieldNames.add(fieldSetMember.getFieldPath());
        }
        this.fieldTokens.addAll(fieldNames);
        return this;
    }

    public QueryBuilder qbFieldSet(String fieldSetName) {
        Set<String> result = new Set<String>();
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = GlobalDescribeMap.get(this.fromSobject);
        List<FieldSetMember> fields = sObjectTypeObj.getDescribe().FieldSets.getMap().get(fieldSetName).getFields();
        for (FieldSetMember fieldSetMember : fields) {
            result.add(fieldSetMember.getFieldPath());
        }
        this.fieldTokens.addAll(result);
        return this;
    }

    //conditions
    public ConditionsManager qbCondition() {
        return this.conditionsManager;
    }

    //limits
    public QueryBuilder setLimit(Integer queryLimit) {
        this.queryLimit = queryLimit;
        return this;
    }

    //orders
    public QueryBuilder orderAsc(String field) {
        this.sortingOrder.add(new AscOrder(field));
        return this;
    }

    public QueryBuilder orderDesc(String field) {
        this.sortingOrder.add(new DescOrder(field));
        return this;
    }


    //result or pre-result managers
    public QueryBuilder preview() {
        String logRecord = '\n============RESULTING QUERY============\n\n'
                + this.toString()
                + '\n\n=======================================\n';
        System.debug(logRecord);
        return this;
    }

    public QueryBuilder previewCount() {
        if(this.countResult == null) {
            this.countResult = this.toCount();
        }
        String logRecord = '\n============COUNT RESULT============\n\n'
                + 'Query will return exactly: ' + this.countResult + ' record(s).'
                + '\n\n=======================================\n';
        System.debug(logRecord);
        return this;
    }

    public QueryBuilder resetQuery() {
        this.result = null;
        return this;
    }

    //results
    public override String toString() {
        String result = 'SELECT ';
        String fields = '';
        if (this.fieldTokens.isEmpty()) {
            fields = 'Id';
        } else {
            fields = String.join(new List<String>(this.fieldTokens), ', ');
        }
        result += fields + ' ';
        result += 'FROM ' + this.fromSobject + ' ';
        if (this.conditionsManager.hasConditions()) {
            result += 'WHERE ' + this.conditionsManager.builtCondition + ' ';
        }
        if (!this.sortingOrder.isEmpty()) {
            result += 'ORDER BY ';
            List<String> orders = new List<String>();
            for (Order order : this.sortingOrder) {
                orders.add(order.toString());
            }
            result += String.join(orders, ', ') + ' ';
        }
        if (this.queryLimit > 0) {
            result += 'LIMIT ' + queryLimit + ' ';
        }
        return result.trim();
    }

    public String toCountString() {
        String result = 'SELECT ';
        String countString = 'count() ';
        result += countString;
        result += 'FROM ' + this.fromSobject + ' ';
        if (this.conditionsManager.hasConditions()) {
            result += 'WHERE ' + this.conditionsManager.builtCondition + ' ';
        }
        return result.trim();
    }

    public Integer toCount() {
        if (this.countResult == null) {
            this.countResult = Database.countQuery(this.toCountString());
        }
        return this.countResult;
    }

    public List<SObject> toList() {
        if (this.result == null) {
            this.result = Database.query(this.toString());
        }
        return this.result;
    }

    public Map<Id, SObject> toMap() {
        return new Map<Id, SObject>(this.toList());
    }

    public Map<Id, SObject> toMap(Map<Id, SObject> mapToFill) {
        for (SObject sobj : this.toList()) {
            Id sobjId = (Id) sobj.get('Id');
            mapToFill.put(sobjId, sobj);
        }
        return mapToFill;
    }

    public SObject toSObject() {
        List<SObject> result = this.toList();
        if (result.isEmpty()) {
            return null;
        }
        return result[0];
    }

    public Set<Id> toIdSet() {
        return this.toMap().keySet();
    }

    public Set<Id> extractIds(String fieldName) {
        Set<Id> result = new Set<Id>();
        for (SObject sobj : this.toList()) {
            String extractedId = (String) sobj.get(fieldName);
            result.add(extractedId);
        }
        return result;
    }

    //post query updater
    public PostQueryUpdater qbUpdater() {
        return this.postQueryUpdater;
    }

    //helper functions
    public QueryBuilder cloneQueryBuilder() {
        return this.cloneQueryBuilder(false);
    }

    public QueryBuilder cloneQueryBuilder(Boolean includeResult) {
        QueryBuilder result = new QueryBuilder();
        result.fromSobject = this.fromSobject;
        result.fieldTokens = new Set<String>(this.fieldTokens);
        result.conditionsManager = this.conditionsManager.cloneConditionsManager(result);
        result.queryLimit = this.queryLimit;
        if (includeResult && this.result != null && !this.result.isEmpty()) {
            result.result = new List<SObject>(this.result);
        }
        result.sortingOrder = new List<Order>(this.sortingOrder);
        result.postQueryUpdater = new PostQueryUpdater(result);
        return result;
    }

    //helper classes

    //conditions
    public class ConditionsManager {

        private final String BRACKET_L = '{';
        private final String BRACKET_R = '}';

        public List<Condition> conditions;
        private String conditionOrder;
        private final QueryBuilder queryBuilder;

        private String builtCondition;

        public ConditionsManager(QueryBuilder queryBuilder) {
            this.queryBuilder = queryBuilder;
            this.conditions = new List<Condition>();
        }

        public ConditionsManager cloneConditionsManager(QueryBuilder queryBuilder) {
            ConditionsManager result = new ConditionsManager(queryBuilder);
            result.conditions = new List<Condition>(this.conditions);
            result.conditionOrder = conditionOrder;
            result.builtCondition = builtCondition;
            return result;
        }

        public ConditionsManager add(Condition condition) {
            if (condition instanceof ObjectTypeDependentCondition) {
                ((ObjectTypeDependentCondition) condition).setRelatedObjectType(this.queryBuilder.fromSobject);
            }
            if (condition.isEmpty()) {
                return this;
            }
            this.conditions.add(condition);
            return this;
        }

        public ConditionsManager preview() {
            System.debug('\nCONDITIONS');
            System.debug(this.buildCondition());
            System.debug('\n');
            return this;
        }

        public ConditionsManager setConditionOrder(String conditionOrder) {
            this.conditionOrder = conditionOrder;
            return this;
        }

        public String buildCondition() {
            String result = this.conditionOrder;
            if (String.isEmpty(result)) {
                result = '1';
            }
            result = this.bracketConditions(result);
            for (Integer i = 0; i < this.conditions.size(); i++) {
                Condition condition = this.conditions[i];
                if (condition instanceof ObjectTypeDependentCondition) {
                    ((ObjectTypeDependentCondition) condition).setRelatedObjectType(this.queryBuilder.fromSobject);
                }
                String conditionNumber = this.bracket('' + (i + 1));
                if(result.contains(conditionNumber)) {
                    result = result.replace(conditionNumber, condition.toString());
                }
            }
            return result;
        }

        public QueryBuilder endCondition() {
            this.builtCondition = this.buildCondition();
            return this.queryBuilder;
        }

        public Boolean hasConditions() {
            return !this.conditions.isEmpty();
        }

        private String bracketConditions(String conditions) {
            this.conditions.size();
            for (Integer i = 1; i <= this.conditions.size(); i++) {
                String conditionNumber = '' + i;
                conditions = conditions.replace(conditionNumber, this.bracket(conditionNumber));
            }
            return conditions;
        }

        private String bracket(String condition) {
            return this.BRACKET_L + condition.trim() + this.BRACKET_R;
        }
    }

    public abstract class Condition {

        public final String QUOTE = '\'';
        public final String BRACKET_L = '(';
        public final String BRACKET_R = ')';
        protected String formedCondition;

        public Condition() {
            this.formedCondition = '';
        }

        protected String quote(String field) {
            return this.QUOTE + String.escapeSingleQuotes(field.trim()) + this.QUOTE;
        }

        protected String bracket(String field) {
            return BRACKET_L + field.trim() + BRACKET_R;
        }

        public virtual override String toString() {
            return this.formedCondition;
        }

        public virtual Boolean isEmpty() {
            return String.isEmpty(this.toString());
        }
    }

    public class SimpleCondition extends Condition {

        public SimpleCondition() {
            super();
        }

        public SimpleCondition(String condition) {
            super();
            this.formedCondition = condition;
        }
    }

    public abstract class FieldCondition extends Condition {

        protected String fieldName;

        public FieldCondition(String fieldName) {
            super();
            this.fieldName = fieldName;
        }

        public FieldCondition(SObjectField fieldName) {
            super();
            this.fieldName = fieldName.getDescribe().getName();
        }

        public override Boolean isEmpty() {
            return String.isEmpty(this.fieldName);
        }
    }

    public class NullCondition extends FieldCondition {

        public NullCondition(String fieldName) {
            super(fieldName);
        }

        public NullCondition(SObjectField fieldName) {
            super(fieldName);
        }

        //null
        public Condition isNull() {
            this.formedCondition = this.fieldName + ' = NULL';
            return this;
        }

        public Condition notNull() {
            this.formedCondition = this.fieldName + ' != NULL';
            return this;
        }
    }

    public class CompareCondition extends FieldCondition {

        public CompareCondition(String fieldName) {
            super(fieldName);
        }

        public CompareCondition(SObjectField fieldName) {
            super(fieldName);
        }

        //string
        public Condition eq(String fieldValue) {
            this.formedCondition = this.fieldName + ' = ' + this.quote(fieldValue);
            return this;
        }

        public Condition ne(String fieldValue) {
            this.formedCondition = this.fieldName + ' != ' + this.quote(fieldValue);
            return this;
        }

        //boolean
        public Condition eq(Boolean fieldValue) {
            this.formedCondition = this.fieldName + ' = ' + fieldValue;
            return this;
        }

        public Condition ne(Boolean fieldValue) {
            this.formedCondition = this.fieldName + ' != ' + fieldValue;
            return this;
        }

        //number
        public Condition eq(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' = ' + fieldValue;
            return this;
        }

        public Condition lt(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' < ' + fieldValue;
            return this;
        }

        public Condition gt(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' > ' + fieldValue;
            return this;
        }

        public Condition lte(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' <= ' + fieldValue;
            return this;
        }

        public Condition gte(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' >= ' + fieldValue;
            return this;
        }

        public Condition ne(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' != ' + fieldValue;
            return this;
        }
    }

    public class LikeCondition extends FieldCondition {

        public LikeCondition(String fieldName) {
            super(fieldName);
        }

        public LikeCondition(SObjectField fieldName) {
            super(fieldName);
        }

        //like
        public Condition likeAnyBoth(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote('%' + fieldValue + '%');
            return this;
        }

        public Condition likeAnyLeft(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote('%' + fieldValue);
            return this;
        }

        public Condition likeAnyRight(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote(fieldValue + '%');
            return this;
        }
    }

    public class InCondition extends FieldCondition {

        public InCondition(String fieldName) {
            super(fieldName);
        }

        public InCondition(SObjectField fieldName) {
            super(fieldName);
        }

        //in - set
        public Condition inCollection(Map<Id, SObject> inSet) {
            return this.inCollection(inSet.keySet());
        }

        public Condition inCollection(Set<String> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inSet);
            return this;
        }

        public Condition inCollection(Set<Id> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inSet);
            return this;
        }

        public Condition inCollection(Set<Decimal> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildInNoQuote(inSet);
            return this;
        }

        //not in
        public Condition notIn(List<SObject> inList) {
            return this.notIn(new Map<Id, SObject>(inList));
        }

        public Condition notIn(Map<Id, SObject> inSet) {
            return this.notIn(inSet.keySet());
        }

        public Condition notIn(Set<Id> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' NOT IN ' + this.buildIn(inSet);
            return this;
        }

        private String buildIn(Set<String> inSet) {
            return this.bracket(
                    + this.QUOTE
                            + String.join(new List<String> (inSet), this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildIn(Set<Id> inSet) {
            return this.bracket(
                    + this.QUOTE
                            + String.join(new List<Id> (inSet), this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildInNoQuote(Set<Decimal> inSet) {
            return this.bracket(
                    + String.join(new List<Decimal> (inSet), ', ')
            );
        }

        //in - list
        public Condition inCollection(List<String> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inList);
            return this;
        }

        public Condition inCollection(List<Id> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inList);
            return this;
        }

        public Condition inCollection(List<Decimal> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildInNoQuote(inList);
            return this;
        }

        private String buildIn(List<String> inList) {
            return this.bracket(
                    + this.QUOTE
                            + String.join(inList, this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildIn(List<Id> inList) {
            return this.bracket(
                    + this.QUOTE
                            + String.join(inList, this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildInNoQuote(List<Decimal> inList) {
            return this.bracket(
                    + String.join(inList, ', ')
            );
        }
    }

    public class ComplexCondition extends Condition {

        private Condition startCondition;
        private List<String> conditionsOrder;
        private List<Condition> conditions;

        public ComplexCondition() {
            super();
            this.startCondition = null;
            this.conditions = new List<Condition>();
            this.conditionsOrder = new List<String>();
        }

        public ComplexCondition startCondition(Condition condition) {
            if (!condition.isEmpty()) {
                this.startCondition = condition;
            }
            return this;
        }

        public ComplexCondition orCondition(Condition condition) {
            if (this.startCondition == null) {
                return this.startCondition(condition);
            }
            this.conditions.add(condition);
            this.conditionsOrder.add('OR');
            return this;
        }

        public ComplexCondition andCondition(Condition condition) {
            if (this.startCondition == null) {
                return this.startCondition(condition);
            }
            this.conditions.add(condition);
            this.conditionsOrder.add('AND');
            return this;
        }

        public ComplexCondition build() {
            if (this.startCondition == null) {
                this.formedCondition = '';
                return this;
            }
            this.formedCondition = this.startCondition.toString() + ' ';
            for (Integer i = 0; i < conditions.size(); i++) {
                String conditionOrder = this.conditionsOrder[i];
                Condition condition = this.conditions[i];
                this.formedCondition += conditionOrder + ' ' + condition.toString() + ' ';
            }
            this.formedCondition = this.bracket(this.formedCondition);
            return this;
        }

        public override Boolean isEmpty() {
            return this.startCondition ==  null;
        }

        public override String toString() {
            this.build();
            return this.formedCondition;
        }

        public String addOrderIfNotEmpty(String order) {
            if (this.isEmpty()) {
                return '';
            }
            return ' ' + order;
        }
    }

    public abstract class ObjectTypeDependentCondition extends Condition {

        private String objectType;

        public ObjectTypeDependentCondition() {
            super();
        }

        public void setRelatedObjectType(String objectType) {
            this.objectType = objectType;
        }
    }

    public class RecordTypeCondition extends ObjectTypeDependentCondition {

        private String recordTypeName;

        public RecordTypeCondition(String recordTypeName) {
            super();
            this.recordTypeName = recordTypeName;
        }

        private Id getRecordTypeId() {
            return Schema.getGlobalDescribe().get(this.objectType).getDescribe().getRecordTypeInfosByName().get(this.recordTypeName).getRecordTypeId();
        }

        public override String toString() {
            this.formedCondition = 'RecordTypeId = ' + this.quote(this.getRecordTypeId());
            return this.formedCondition;
        }
    }

    //post query updater
    public class PostQueryUpdater {

        public final List<Updater> updaters;
        private final QueryBuilder queryBuilder;

        public PostQueryUpdater(QueryBuilder queryBuilder) {
            this.queryBuilder = queryBuilder;
            this.updaters = new List<Updater>();
        }

        public PostQueryUpdater add(Updater updater) {
            this.updaters.add(updater);
            return this;
        }

        public QueryBuilder performUpdate() {
            List<SObject> toUpdate = this.queryBuilder.toList();
            for (SObject sobj : toUpdate) {
                for (Updater updater : this.updaters) {
                    updater.applyUpdate(sobj);
                }
            }
            update toUpdate;
            return this.queryBuilder;
        }
    }

    public abstract class Updater {

        public Updater() {
        }

        protected abstract Updater applyUpdate(SObject sobj);
    }

    public abstract class FieldUpdater extends Updater {

        protected String fieldName;

        public FieldUpdater(String fieldName) {
            super();
            this.fieldName = fieldName;
        }

        public FieldUpdater(SObjectField fieldName) {
            super();
            this.fieldName = fieldName.getDescribe().getName();
        }
    }

    public class FieldUpdate extends FieldUpdater {

        private Object value;

        public FieldUpdate(String fieldName) {
            super(fieldName);
        }

        public FieldUpdate(SObjectField fieldName) {
            super(fieldName);
        }

        public Updater set(Object value) {
            this.value = value;
            return this;
        }

        protected override Updater applyUpdate(SObject sobj) {
            sobj.put(this.fieldName, this.value);
            return this;
        }
    }

    //orders
    public virtual class Order {

        private final String sortingField;
        private final String sortingOrder;

        public Order(String sortingField, String sortingOrder) {
            this.sortingField = sortingField;
            this.sortingOrder = sortingOrder;
        }

        public override String toString() {
            return sortingField + ' ' + sortingOrder;
        }
    }

    public class AscOrder extends Order {

        public AscOrder(String sortingField) {
            super(sortingField, 'ASC');
        }
    }

    public class DescOrder extends Order {

        public DescOrder(String sortingField) {
            super(sortingField, 'DESC');
        }
    }

    //exceptions
    public class QueryBuilderException extends Exception {}
}