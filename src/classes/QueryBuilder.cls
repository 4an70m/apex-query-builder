/**
    MIT License

    Copyright (c) 2018 Alex

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

public virtual with sharing class QueryBuilder {

    private String fromSobject;
    private Set<String> fieldTokens;
    private Set<String> groupByFields;
    private List<Order> sortingOrder;
    private Integer queryLimit;
    private Integer queryOffset;
    private Integer countResult;

    private StubbedQueryBuilder stubbedQueryBuilder;

    private ConditionsManager conditionsManager;

    private List<SObject> result;

    public QueryBuilder() {
        this.fieldTokens = new Set<String>();
        this.groupByFields = new Set<String>();
        this.sortingOrder = new List<Order>();
        this.conditionsManager = new ConditionsManager(this);
        this.queryLimit = 0;
        this.queryOffset = 0;
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
    
    //from
    public QueryBuilder addFrom(String fromSobject) {
        this.fromSobject = fromSobject;
        return this;
    }

    public QueryBuilder addFrom(Type type) {
        return this.addFrom(type.getName());
    }

    public QueryBuilder addFrom(SObjectType type) {
        return this.addFrom(type.getDescribe().getName());
    }

    public QueryBuilder addFrom(SObject sobj) {
        return this.addFrom(sobj.getSObjectType());
    }

    //subQuery
    public QueryBuilder addSubQuery(QueryBuilder queryBuilder) {
        return this.addField('(' + queryBuilder.toString() + ')');
    }

    public QueryBuilder addSubQuery(String subQueryString) {
        return this.addField('(' + subQueryString + ')');
    }

    //fields
    public QueryBuilder addField(String fieldName) {
        if (fieldName.contains(',')) {
            return this.addFields(fieldName);
        }
        this.fieldTokens.add(fieldName.trim());
        return this;
    }

    public QueryBuilder addField(SObjectField field) {
        return this.addField(field.getDescribe().getName());
    }

    public QueryBuilder addFields(SObject sobj) {
        return this.addFields(sobj.getPopulatedFieldsAsMap().keySet());
    }

    public QueryBuilder addFields(String fieldNames) {
        return this.addFields(fieldNames.trim().split(','));
    }

    public QueryBuilder addFields(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.fieldTokens.add(fieldName.trim());
        }
        return this;
    }

    public QueryBuilder addFields(Set<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.fieldTokens.add(fieldName.trim());
        }
        return this;
    }

    //all fields
    public QueryBuilder addFieldsAll() {
        return this.addFieldsAll(this.fromSobject);
    }

    public QueryBuilder addFieldsAll(String sobjectName) {
        Set<String> fieldNames = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap().keySet();
        this.fieldTokens.addAll(fieldNames);
        return this;
    }

    public QueryBuilder addFieldsAll(Type sobjectType) {
        return this.addFieldsAll(sobjectType.toString());
    }

    public QueryBuilder addFieldsAllCreatable() {
        return this.addFieldsAllCreatable(this.fromSobject);
    }

    public QueryBuilder addFieldsAllCreatable(String sobjectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        Set<String> createableFields = new Set<String>{
        };
        for (Schema.SObjectField field : fieldMap.values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCreateable()) {
                createableFields.add(fieldDescribe.getName());
            }
        }
        fieldTokens.addAll(createableFields);
        return this;
    }

    public QueryBuilder addFieldsAllCreatable(Type sobjectType) {
        return this.addFieldsAllCreatable(sobjectType.toString());
    }

    public QueryBuilder addFieldsAllUpdatable() {
        return this.addFieldsAllUpdatable(this.fromSobject);
    }

    public QueryBuilder addFieldsAllUpdatable(String sobjectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        Set<String> createableFields = new Set<String>{
        };
        for (Schema.SObjectField field : fieldMap.values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isUpdateable()) {
                createableFields.add(fieldDescribe.getName());
            }
        }
        fieldTokens.addAll(createableFields);
        return this;
    }

    public QueryBuilder addFieldsAllUpdatable(Type sobjectType) {
        return this.addFieldsAllUpdatable(sobjectType.toString());
    }

    //field sets
    public QueryBuilder addFieldSet(String objectName, String fieldSetName) {
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

    public QueryBuilder addFieldSet(FieldSet fieldSet) {
        Set<String> fieldNames = new Set<String>();
        for (FieldSetMember fieldSetMember : fieldSet.getFields()) {
            fieldNames.add(fieldSetMember.getFieldPath());
        }
        this.fieldTokens.addAll(fieldNames);
        return this;
    }

    public QueryBuilder addFieldSet(String fieldSetName) {
        return this.addFieldSet(this.fromSobject, fieldSetName);
    }

    //conditions
    public ConditionsManager addConditions() {
        return this.conditionsManager;
    }

    public ConditionsManager addConditionsWithOrder(String conditionOrder) {
        return this.conditionsManager.setConditionOrder(conditionOrder);
    }

    //limits
    public QueryBuilder setLimit(Integer queryLimit) {
        this.queryLimit = queryLimit;
        return this;
    }

    //offset
    public QueryBuilder setOffset(Integer queryOffset) {
        this.queryOffset = queryOffset;
        return this;
    }

    //orders
    public QueryBuilder addOrderAsc(String field) {
        this.sortingOrder.add(new AscOrder(field));
        return this;
    }

    public QueryBuilder addOrderAsc(SObjectField sObjectField) {
        this.sortingOrder.add(new AscOrder(sObjectField.getDescribe().getName()));
        return this;
    }

    public QueryBuilder addOrderDesc(String field) {
        this.sortingOrder.add(new DescOrder(field));
        return this;
    }

    public QueryBuilder addOrderDesc(SObjectField sObjectField) {
        this.sortingOrder.add(new DescOrder(sObjectField.getDescribe().getName()));
        return this;
    }

    //group by
    public QueryBuilder addGroupBy(SObjectField field) {
        return this.addGroupBy(field.getDescribe().getName());
    }

    public QueryBuilder addGroupBy(String fields) {
        return this.addGroupBy(fields.trim().split(','));
    }

    public QueryBuilder addGroupBy(List<String> fields) {
        this.groupByFields.addAll(fields);
        return this;
    }

    public QueryBuilder addGroupBy(Set<String> fields) {
        this.groupByFields.addAll(fields);
        return this;
    }

    //stub method
    public StubbedQueryBuilder buildStub() {
        this.stubbedQueryBuilder = new StubbedQueryBuilder(this);
        return this.stubbedQueryBuilder;
    }

    //pre-result managers
    public QueryBuilder preview() {
        String logRecord = '\n============RESULTING QUERY============\n\n'
                + this.toString()
                + '\n\n=======================================\n';
        System.debug(logRecord);
        return this;
    }

    public QueryBuilder previewCount() {
        if (this.countResult == null) {
            this.countResult = this.toCount();
        }
        String logRecord = '\n============COUNT RESULT============\n\n'
                + 'Query will return exactly: ' + this.countResult + ' record(s).'
                + '\n\n=======================================\n';
        System.debug(logRecord);
        return this;
    }

    public QueryBuilder newQuery() {
        this.fieldTokens = new Set<String>();
        this.groupByFields = new Set<String>();
        this.sortingOrder = new List<Order>();
        this.conditionsManager = new ConditionsManager(this);
        this.queryLimit = 0;
        this.queryOffset = 0;
        this.countResult = null;
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
        if (!this.groupByFields.isEmpty()) {
            result += 'GROUP BY ';
            result += String.join(new List<String>(this.groupByFields), ', ') + ' ';
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

    public String toStringCount() {
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
            this.countResult = Database.countQuery(this.toStringCount());
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
            if (String.isEmpty(extractedId)) {
                continue;
            }
            result.add(extractedId);
        }
        return result;
    }

    public List<Object> extractField(String fieldName) {
        List<Object> result = new List<Object>();
        for (SObject sobj : this.toList()) {
            result.add(sobj.get(fieldName));
        }
        return result;
    }

    //helper functions
    public QueryBuilder cloneQueryBuilder() {
        return this.cloneQueryBuilder(false);
    }

    public QueryBuilder cloneQueryBuilder(Boolean includeResult) {
        QueryBuilder result = new QueryBuilder(this.fromSobject);
        result.addFields(this.fieldTokens);
        result.addGroupBy(this.groupByFields);
        result.conditionsManager = this.conditionsManager.cloneConditionsManager(result);
        result.setLimit(this.queryLimit);
        if (includeResult && this.result != null && !this.result.isEmpty()) {
            result.result = new List<SObject>(this.result);
        }
        result.sortingOrder.addAll(this.sortingOrder);
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
            System.debug(this.toString());
            System.debug('\n');
            return this;
        }

        public ConditionsManager setConditionOrder(String conditionOrder) {
            this.conditionOrder = conditionOrder;
            return this;
        }

        public QueryBuilder endConditions() {
            this.builtCondition = this.toString();
            return this.queryBuilder;
        }

        public override String toString() {
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
                if (result.contains(conditionNumber)) {
                    result = result.replace(conditionNumber, condition.toString());
                }
            }
            return result;
        }

        private Boolean hasConditions() {
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
        public Condition inCollection(List<SObject> inList) {
            return this.inCollection(new Map<Id, SObject>(inList));
        }

        public Condition inCollection(Map<Id, SObject> inKeySet) {
            return this.inCollection(inKeySet.keySet());
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

        //not in set
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
                    +this.QUOTE
                            + String.join(new List<String> (inSet), this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildIn(Set<Id> inSet) {
            return this.bracket(
                    +this.QUOTE
                            + String.join(new List<Id> (inSet), this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildInNoQuote(Set<Decimal> inSet) {
            return this.bracket(String.join(new List<Decimal> (inSet), ', '));
        }

        //in - list
        public Condition inCollection(List<Id> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inList);
            return this;
        }

        public Condition inCollection(List<String> inList) {
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
                    +this.QUOTE
                            + String.join(inList, this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildIn(List<Id> inList) {
            return this.bracket(
                    +this.QUOTE
                            + String.join(inList, this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildInNoQuote(List<Decimal> inList) {
            return this.bracket(String.join(inList, ', '));
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
            return this.startCondition == null;
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

    //mocking provider
    public class QueryBuilderMockProvider implements System.StubProvider {

        private StubbedQueryBuilder stubbedQueryBuilder;

        public QueryBuilderMockProvider(StubbedQueryBuilder stubbedQueryBuilder) {
            this.stubbedQueryBuilder = stubbedQueryBuilder;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'toString' {
                    return this.stubbedQueryBuilder.stubToString();
                }
                when 'toStringCount' {
                    return this.stubbedQueryBuilder.stubToStringCount();
                }
                when 'toCount' {
                    return this.stubbedQueryBuilder.stubToCount();
                }
                when 'toList' {
                    return this.stubbedQueryBuilder.stubToList();
                }
                when 'toMap' {
                    if (listOfArgs.isEmpty()) {
                        return this.stubbedQueryBuilder.stubToMap();
                    } else {
                        return this.stubbedQueryBuilder.stubToMap((Map<Id, SObject>)listOfArgs[0]);
                    }
                }
                when 'toSObject' {
                    return this.stubbedQueryBuilder.stubToSObject();
                }
                when 'toIdSet' {
                    return this.stubbedQueryBuilder.stubToIdSet();
                }
                when 'extractIds' {
                    return this.stubbedQueryBuilder.stubExtractIds((String)listOfArgs[0]);
                }
                when 'extractField' {
                    return this.stubbedQueryBuilder.stubExtractField((String)listOfArgs[0]);
                }
                when 'addConditions' {
                    return this.stubbedQueryBuilder.stubbedConditionsManager;
                }
            }
            return stubbedObject;
        }
    }

    public class ConditionsManagerMockProvider implements System.StubProvider {

        public StubbedQueryBuilder stubbedQueryBuilder;

        public ConditionsManagerMockProvider(StubbedQueryBuilder stubbedQueryBuilder) {
            this.stubbedQueryBuilder = stubbedQueryBuilder;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'endConditions' {
                    return this.stubbedQueryBuilder;
                }
                when 'toString' {
                    return '';
                }
            }
            return stubbedObject;
        }
    }

    public class StubbedQueryBuilder extends QueryBuilder{

        private QueryBuilder parent;
        private String queryString;
        private String queryCountString;
        private Integer countResult;
        private List<SObject> toListResult;
        private Map<Id, SObject> toMapResult;
        private Map<Id, SObject> toMapFillResult;
        private SObject toSobjectResult;
        private Set<Id> toSetIdResult;
        private Set<Id> extractedIdsResult;
        private List<Object> extractedFieldsResult;
        private ConditionsManager stubbedConditionsManager;
        private QueryBuilder stubbedQueryBuilder;

        public StubbedQueryBuilder(QueryBuilder parent) {
            super();
            this.parent = parent;
            this.stubbedQueryBuilder = (QueryBuilder) Test.createStub(QueryBuilder.class, new QueryBuilderMockProvider(this));
            this.stubbedConditionsManager = this.parent.conditionsManager.cloneConditionsManager(this.stubbedQueryBuilder);
        }

        //end stub and return to normal Query builder flow
        public QueryBuilder applyStub() {
            if (Test.isRunningTest()) {
                this.parent = this.stubbedQueryBuilder;
            }
            return (QueryBuilder) this.parent;
        }

        //stub building methods
        public StubbedQueryBuilder addStubToString(String queryString) {
            this.queryString = queryString;
            return this;
        }

        public StubbedQueryBuilder addStubToStringCount(String queryCountString) {
            this.queryCountString = queryCountString;
            return this;
        }

        public StubbedQueryBuilder addStubToCount(Integer countResult) {
            this.countResult = countResult;
            return this;
        }

        public StubbedQueryBuilder addStubToList(List<SObject> toListResult) {
            this.toListResult = toListResult;
            return this;
        }

        public StubbedQueryBuilder addStubToMap(Map<Id, SObject> toMapResult) {
            this.toMapResult = toMapResult;
            return this;
        }

        public StubbedQueryBuilder addStubToSObject(SObject toSobjectResult) {
            this.toSobjectResult = toSobjectResult;
            return this;
        }

        public StubbedQueryBuilder addStubToIdSet(Set<Id> toSetIdResult) {
            this.toSetIdResult = toSetIdResult;
            return this;
        }

        public StubbedQueryBuilder addStubExtractIds(Set<Id> extractedIdsResult) {
            this.extractedIdsResult = extractedIdsResult;
            return this;
        }

        public StubbedQueryBuilder addStubExtractField(List<Object> extractedFieldsResult) {
            this.extractedFieldsResult = extractedFieldsResult;
            return this;
        }

        //stub methods to call
        private String stubToString() {
            return this.queryString;
        }

        private String stubToStringCount() {
            return this.queryCountString;
        }

        private Integer stubToCount() {
            return this.countResult;
        }

        private List<SObject> stubToList() {
            return this.toListResult;
        }

        private Map<Id, SObject> stubToMap() {
            return this.toMapResult;
        }

        private Map<Id, SObject> stubToMap(Map<Id, SObject> mapToFill) {
            mapToFill = this.toMapFillResult;
            return this.toMapFillResult;
        }

        private SObject stubToSObject() {
            return this.toSobjectResult;
        }

        private Set<Id> stubToIdSet() {
            return this.toSetIdResult;
        }

        private Set<Id> stubExtractIds(String fieldName) {
            return this.extractedIdsResult;
        }

        private List<Object> stubExtractField(String fieldName) {
            return this.extractedFieldsResult;
        }
    }

    //exceptions (reserved for later use)
    public class QueryBuilderException extends Exception {
    }
}