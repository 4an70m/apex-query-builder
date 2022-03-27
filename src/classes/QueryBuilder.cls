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

/**
 * Basic class and a namespace for all query building methods.
 *
 * @author github.com/4an70m
 * @version 1.0
 */
public virtual inherited sharing class QueryBuilder {

    public enum FilterScope {
        Delegated,
        Everything,
        Mine,
        MineAndMyGroups,
        My_Territory,
        My_Team_Territory,
        Team
    }

    private String fromSobject;
    private Set<String> fieldTokens;
    private Set<String> groupByFields;
    private List<Order> sortingOrder;
    private FilterScope scope;
    private Integer queryLimit;
    private Integer queryOffset;
    private Integer countResult;
    private Boolean updateTracking;
    private Boolean updateViewstat;
    private Boolean forView;
    private Boolean forReference;
    private Boolean withSecurityEnforced;

    private StubbedQueryBuilder stubbedQueryBuilder;

    private ConditionsManager conditionsManager;

    private List<SObject> result;
    private Boolean checkCrud;
    private Boolean checkFls;

    /**
     * Constructs an empty QueryBuilder instance.
     * Requires a call to addFrom() method for selecting
     * an sobject to build query for.
     *
     * @see QueryBuilder.addFrom
     */
    public QueryBuilder() {
        this.fieldTokens = new Set<String>();
        this.groupByFields = new Set<String>();
        this.sortingOrder = new List<Order>();
        this.conditionsManager = new ConditionsManager(this);
        this.queryLimit = 0;
        this.queryOffset = 0;
        this.countResult = null;
        this.checkCrud = false;
        this.checkFls = false;
        this.updateTracking = false;
        this.updateViewstat = false;
        this.forView = false;
        this.forReference = false;
        this.withSecurityEnforced = false;
        this.scope = FilterScope.Everything;
    }

    /**
     * Constructs a QueryBuilder instance for
     * given SObject name in a string form.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder('Account');
     * </code>
     * </pre>
     *
     * @param fromSobject
     */
    public QueryBuilder(String fromSobject) {
        this();
        this.fromSobject = fromSobject.trim();
    }

    /**
     * Constructs a QueryBuilder instance for
     * given SObject name in an SObjectType form.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     */
    public QueryBuilder(SObjectType type) {
        this();
        this.fromSobject = type.getDescribe().getName();
    }

    /**
     * Constructs a QueryBuilder instance for
     * given SObject name in an System.Type form.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     */
    public QueryBuilder(Type type) {
        this();
        this.fromSobject = type.getName();
    }

    /**
     * Constructs a QueryBuilder instance for
     * given SObject name in an SObject form.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     */
    public QueryBuilder(SObject sobj) {
        this(sobj.getSObjectType());
    }

    /**
     * Sets the FROM statement in the query.
     * Always overrides the constructor-selected FROM value.
     * <br/>
     * The name of the SObject is accepted as a string.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFrom('Account');
     * </code>
     * </pre>
     *
     * @param fromSobject
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFrom(String fromSobject) {
        this.fromSobject = fromSobject;
        return this;
    }

    /**
     * Sets the FROM statement in the query.
     * Always overrides the constructor-selected FROM value.
     * <br/>
     * The name of the SObject is accepted as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFrom(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFrom(SObjectType type) {
        return this.addFrom(type.getDescribe().getName());
    }

    /**
     * Sets the FROM statement in the query.
     * Always overrides the constructor-selected FROM value.
     * <br/>
     * The name of the SObject is accepted as a System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFrom(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFrom(Type type) {
        return this.addFrom(type.getName());
    }

    /**
     * Sets the FROM statement in the query.
     * Always overrides the constructor-selected FROM value.
     * <br/>
     * The name of the SObject is accepted as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFrom(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFrom(SObject sobj) {
        return this.addFrom(sobj.getSObjectType());
    }

    /**
     * Constructs a sub-query for given query.
     * The sub-query is build based on a nested QueryBuilder instance.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addSubQuery(new QueryBuilder('Contacts'));
     * </code>
     * </pre>
     *
     * @param queryBuilder
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addSubQuery(QueryBuilder queryBuilder) {
        return this.addSubQuery(queryBuilder.toString());
    }

    /**
     * Constructs a sub-query for given query.
     * The sub-query is a plain string value.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addSubQuery('SELECT Id FROM Contacts');
     * </code>
     * </pre>
     *
     * @param subQueryString
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addSubQuery(String subQueryString) {
        this.fieldTokens.add('(' + subQueryString + ')');
        return this;
    }

    /**
     * Adds a field or number of comma-separated fields
     * into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addField('Id')
     *     .addField('Name, ParentId');
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addField(String fieldName) {
        if (fieldName.contains(',')) {
            return this.addFields(fieldName);
        }
        this.fieldTokens.add(fieldName.trim());
        return this;
    }

    /**
     * Adds a field in a form of SObjectField
     * into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addField(Account.Name);
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addField(SObjectField field) {
        return this.addField(field.getDescribe().getName());
    }

    /**
     * Adds a field or number of populated fields,
     * extracted from sobject instance into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addField(new Account(Name = 'Test'));
     * //results: SELECT Name FROM Account
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(SObject sobj) {
        return this.addFields(sobj.getPopulatedFieldsAsMap().keySet());
    }

    /**
     * Adds a field or number of comma-separated fields
     * into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFields('Id')
     *     .addFields('Name, ParentId');
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(String fieldNames) {
        return this.addFields(fieldNames.trim().split(','));
    }

    /**
     * Adds a list of fields into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFields(new List<String> {'Name'});
     * </code>
     * </pre>
     *
     * @param fieldNames
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.fieldTokens.add(fieldName.trim());
        }
        return this;
    }

    /**
     * Adds a set of fields into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFields(new Set<String> {'Name'});
     * </code>
     * </pre>
     *
     * @param fieldNames
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(Set<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.fieldTokens.add(fieldName.trim());
        }
        return this;
    }

    /**
     * Adds all fields of the sobject, specified in FROM statement.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFieldsAll();
     * </code>
     * </pre>
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll() {
        return this.addFieldsAll(this.fromSobject);
    }

    /**
     * Adds all fields of the sobject, specified in param as a string name.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll('Account');
     * </code>
     * </pre>
     *
     * @param sobjectName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll(String sobjectName) {
        Set<String> fieldNames = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap().keySet();
        this.fieldTokens.addAll(fieldNames);
        return this;
    }

    /**
     * Adds all fields of the sobject, specified in param as System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll(Type type) {
        return this.addFieldsAll(type.toString());
    }

    /**
     * Adds all fields of the sobject, specified in param as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll(SObjectType type) {
        return this.addFieldsAll(type.getDescribe().getName());
    }

    /**
     * Adds all fields of the sobject, specified in param as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll(SObject sobj) {
        return this.addFieldsAll(sobj.getSObjectType());
    }

    /**
     * Adds all creatable fields of the sobject, specified in FROM statement.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllCreatable();
     * </code>
     * </pre>
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable() {
        return this.addFieldsAllCreatable(this.fromSobject);
    }

    /**
     * Adds all creatable fields of the sobject, specified in param as a string name.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllCreatable('Account');
     * </code>
     * </pre>
     *
     * @param sobjectName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable(String sobjectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        Set<String> createableFields = new Set<String>();
        for (Schema.SObjectField field : fieldMap.values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCreateable()) {
                createableFields.add(fieldDescribe.getName());
            }
        }
        fieldTokens.addAll(createableFields);
        return this;
    }

    /**
     * Adds all creatable fields of the sobject, specified in param as System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllCreatable(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable(Type type) {
        return this.addFieldsAllCreatable(type.toString());
    }

    /**
     * Adds all creatable fields of the sobject, specified in param as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable(SObjectType type) {
        return this.addFieldsAllCreatable(type.getDescribe().getName());
    }

    /**
     * Adds all creatable fields of the sobject, specified in param as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable(SObject sobj) {
        return this.addFieldsAllCreatable(sobj.getSObjectType());
    }

    /**
     * Adds all updatable fields of the sobject, specified in FROM statement.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable();
     * </code>
     * </pre>
     *
     * @param sobjectName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable() {
        return this.addFieldsAllUpdatable(this.fromSobject);
    }

    /**
     * Adds all updatable fields of the sobject, specified in param as string name.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable('Account');
     * </code>
     * </pre>
     *
     * @param sobjectName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable(String sobjectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        Set<String> updateableFields = new Set<String>{
        };
        for (Schema.SObjectField field : fieldMap.values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isUpdateable()) {
                updateableFields.add(fieldDescribe.getName());
            }
        }
        fieldTokens.addAll(updateableFields);
        return this;
    }

    /**
     * Adds all updatable fields of the sobject, specified in param as System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable(Type type) {
        return this.addFieldsAllUpdatable(type.getName());
    }

    /**
     * Adds all updatable fields of the sobject, specified in param as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable(SObjectType type) {
        return this.addFieldsAllUpdatable(type.getDescribe().getName());
    }

    /**
     * Adds all updatable fields of the sobject, specified in param as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable(SObject sobj) {
        return this.addFieldsAllUpdatable(sobj.getSObjectType());
    }

    /**
     * Adds all fields from a FieldSet for specific object.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFieldSet('Account', 'My_Field_Set');
     * </code>
     * </pre>
     *
     * @param objectName
     * @param fieldSetName
     *
     * @return this - current instance of QueryBuilder.class
     */
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

    /**
     * Adds all fields from a specific FieldSet.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * FieldSet myFieldSet = //retrieve a field set
     * new QueryBuilder(Account.class)
     *     .addFieldSet(myFieldSet);
     * </code>
     * </pre>
     *
     * @param fieldSet
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldSet(FieldSet fieldSet) {
        Set<String> fieldNames = new Set<String>();
        for (FieldSetMember fieldSetMember : fieldSet.getFields()) {
            fieldNames.add(fieldSetMember.getFieldPath());
        }
        this.fieldTokens.addAll(fieldNames);
        return this;
    }

    /**
     * Adds all fields from a specific FieldSet by its name.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFieldSet('My_Field_Set');
     * </code>
     * </pre>
     *
     * @param fieldSetName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldSet(String fieldSetName) {
        return this.addFieldSet(this.fromSobject, fieldSetName);
    }

    /**
     * Returns an instance of ConditionsManage for current QueryBuilder instance.
     * Allows creation of conditions for a query.
     * <p>To finish work with conditions and return to work with QueryBuilder instance
     * it is required to call the endConditions() method of ConditionsManager</p>
     *
     * @return an instance of ConditionsManager.class
     *
     * @see QueryBuilder.ConditionsManager
     */
    public ConditionsManager addConditions() {
        return this.conditionsManager;
    }

    /**
     * Returns an instance of ConditionsManage for current QueryBuilder instance.
     * Allows creation of conditions for a query.
     * <p>As a parameter accepts a string with order of conditions execution and there relations</p>
     * <p>To finish work with conditions and return to work with QueryBuilder instance
     * it is required to call the endConditions() method of ConditionsManager</p>
     * <p>Condition index is 1-based<p>
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addConditionsWithOrder('1 and (2 or 3) and 4')
     *     .endConditions();
     * </code>
     * </pre>
     *
     * @param conditionOrder
     *
     * @return an instance of ConditionsManager.class
     *
     * @see QueryBuilder.ConditionsManager
     */
    public ConditionsManager addConditionsWithOrder(String conditionOrder) {
        return this.conditionsManager.setConditionOrder(conditionOrder);
    }

    /**
     * Sets a limit for current query. Accepts an integer.
     *
     * @param queryLimit
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setLimit(Integer queryLimit) {
        this.queryLimit = queryLimit;
        return this;
    }

    /**
     * Sets an offset for current query. Accepts an integer.
     *
     * @param queryOffset
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setOffset(Integer queryOffset) {
        this.queryOffset = queryOffset;
        return this;
    }

    /**
     * Adds a SORT BY {Order} statement to the query.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrder(
     *          new QueryBuilder.Order(Account.Id)
     *              .setSortingOrderAsc()
     *              .setNullsOrderLast()
     *      );
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrder(Order order) {
        this.sortingOrder.add(order);
        return this;
    }

    /**
     * Adds a SORT BY {field} ASC statement to the query.
     * Field name is specified as a string.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrderAsc('Account');
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrderAsc(String fieldName) {
        this.sortingOrder.add(new AscOrder(fieldName));
        return this;
    }

    /**
     * Adds a SORT BY {field} ASC statement to the query.
     * Field is specified as an SObjectField.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrderAsc(Account.Name);
     * </code>
     * </pre>
     *
     * @param field
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrderAsc(SObjectField field) {
        this.sortingOrder.add(new AscOrder(field.getDescribe().getName()));
        return this;
    }

    /**
     * Adds a SORT BY {field} DESC statement to the query.
     * Field name is specified as a string.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrderDesc('Account');
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrderDesc(String fieldName) {
        this.sortingOrder.add(new DescOrder(fieldName));
        return this;
    }

    /**
     * Adds a SORT BY {field} DESC statement to the query.
     * Field is specified as an SObjectField.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrderDesc(Account.Name);
     * </code>
     * </pre>
     *
     * @param field
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrderDesc(SObjectField field) {
        this.sortingOrder.add(new DescOrder(field.getDescribe().getName()));
        return this;
    }

    /**
     * Adds a field or number of comma-separated fields to the
     * group by Set of fields.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .groupBy('Name')
     *     .groupBy('Id, ParentId');
     * </code>
     * </pre>
     *
     * @param fields
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addGroupBy(String fields) {
        return this.addGroupBy(fields.trim().split(','));
    }

    /**
     * Adds a field in an SObjectField form to the
     * group by Set of fields.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .groupBy(Account.Name);
     * </code>
     * </pre>
     *
     * @param field
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addGroupBy(SObjectField field) {
        return this.addGroupBy(field.getDescribe().getName());
    }

    /**
     * Adds a list of field to the
     * group by Set of fields.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .groupBy(new List<String> {'Name'});
     * </code>
     * </pre>
     *
     * @param fields
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addGroupBy(List<String> fields) {
        this.groupByFields.addAll(fields);
        return this;
    }

    /**
     * Adds a set of field to the
     * group by Set of fields.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .groupBy(new Set<String> {'Name'});
     * </code>
     * </pre>
     *
     * @param fields
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addGroupBy(Set<String> fields) {
        this.groupByFields.addAll(fields);
        return this;
    }

    /**
     * Adds the optional USING SCOPE clause of a SOQL query returns
     * records within a specified scope. For example, you can limit
     * the records to return only objects that the user owns
     * or only records in the user’s territory.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setScope(QueryBuilder.FilterScope.Mine);
     * </code>
     * </pre>
     *
     * @param scope
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setScope(QueryBuilder.FilterScope scope) {
        this.scope = scope;
        return this;
    }

    /**
     * Adds FOR VIEW clause in to the query.
     * Allows to update LastViewedDate on retrieved objects.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setForView(true);
     * </code>
     * </pre>
     *
     * @param forView
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setForView(Boolean forView) {
        this.forView = this.forView;
        return this;
    }

    /**
     * Adds FOR VIEW clause in to the query.
     * Allows to update LastViewedDate on retrieved objects.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setForView();
     * </code>
     * </pre>
     *
     * @param forView
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setForView() {
        this.forView = true;
        return this;
    }

    /**
     * Adds FOR REFERENCE clause in to the query.
     * Allows to update LastReferencedDate on retrieved objects.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setForReference(true);
     * </code>
     * </pre>
     *
     * @param forReference
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setForReference(Boolean forReference) {
        this.forReference = this.forReference;
        return this;
    }

    /**
     * Adds FOR REFERENCE clause in to the query.
     * Allows to update LastReferencedDate on retrieved objects.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setForView();
     * </code>
     * </pre>
     *
     * @param forReference
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setForReference() {
        this.forReference = true;
        return this;
    }

    /**
     * Sets the UPDATE TRACKING optional clause on a SOQL query.
     * UPDATE TRACKING can be added to a SELECT statement of a
     * SOQL query to report on article searches and views to track
     * the keywords that are used in Salesforce Knowledge article searches
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setUpdateTracking(true);
     * </code>
     * </pre>
     *
     * @return
     */
    public QueryBuilder setUpdateTracking(Boolean updateTracking) {
        this.updateTracking = updateTracking;
        return this;
    }

    /**
     * Sets the UPDATE TRACKING optional clause on a SOQL query.
     * UPDATE TRACKING can be added to a SELECT statement of a
     * SOQL query to report on article searches and views to track
     * the keywords that are used in Salesforce Knowledge article searches
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setUpdateTracking();
     * </code>
     * </pre>
     *
     * @return
     */
    public QueryBuilder setUpdateTracking() {
        return this.setUpdateTracking(true);
    }

    /**
     * Adds the UPDATE VIEWSTAT optional clause to the SOQL query.
     * Allows get a view count for every article that you have access to online.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setUpdateViewstat(true);
     * </code>
     * </pre>
     *
     * @return
     */
    public QueryBuilder setUpdateViewstat(Boolean updateViewstat) {
        this.updateViewstat = updateViewstat;
        return this;
    }

    /**
     * Adds the UPDATE VIEWSTAT optional clause to the SOQL query.
     * Allows get a view count for every article that you have access to online.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setUpdateViewstat();
     * </code>
     * </pre>
     *
     * @return
     */
    public QueryBuilder setUpdateViewstat() {
        return this.setUpdateViewstat(true);
    }

    /**
     * Enables or disables CRUD and FLS check for current query.
     * Default is disabled.
     * <br/>
     * Enabled CRUD check throws an System.NoAccessException if current user doesn't have access to an SObject.
     * <br/>
     * Enabled FLS check removes a field from result.
     *
     * @param checkCrudAndFls
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckCRUDAndFLS(Boolean checkCrudAndFls) {
        this.setCheckCRUD(checkCrudAndFls);
        return this.setCheckFLS(checkCrudAndFls);
    }

    /**
     * <h1>THIS IS BETA FUNCTIONALITY</h1>
     * Enables CRUD and FLS check for current query.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setWithSecurityEnforced() {
        return this.setWithSecurityEnforced(true);
    }

    /**
     * <h1>THIS IS BETA FUNCTIONALITY</h1>
     * Enables CRUD and FLS check for current query.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setWithSecurityEnforced(Boolean withSecurityEnforced) {
        this.withSecurityEnforced = withSecurityEnforced;
        return this;
    }

    /**
     * Enables CRUD and FLS check for current query.
     * <br/>
     * Enabled CRUD check throws an System.NoAccessException if current user doesn't have access to an SObject.
     * <br/>
     * Enabled FLS check removes a field from result.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckCRUDAndFLS() {
        return this.setCheckCRUDAndFLS(true);
    }

    /**
     * Enables or disables CRUD check for current query.
     * <br/>
     * Enabled CRUD check throws an System.NoAccessException if current user doesn't have access to an SObject.
     *
     * @param checkCrud
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckCRUD(Boolean checkCrud) {
        this.checkCrud = checkCrud;
        return this;
    }

    /**
     * Enables CRUD check for current query.
     * <br/>
     * Enabled CRUD check throws an System.NoAccessException if current user doesn't have access to an SObject.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckCRUD() {
        return this.setCheckCRUD(true);
    }

    /**
     * Enables or disables FLS check for current query.
     * Default is disabled.
     * <br/>
     * Enabled FLS check removes a field from result.
     *
     * @param checkFls
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckFLS(Boolean checkFls) {
        this.checkFls = checkFls;
        return this;
    }

    /**
     * Enables FLS check for current query.
     * <br/>
     * Enabled FLS check removes a field from result.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckFLS() {
        return this.setCheckFLS(true);
    }

    /**
     * Returns an instance of StubbedQueryBuilder, which can be used in Unit Tests.
     *
     * @return a new instance of QueryBuilder.StubbedQueryBuilder.class
     */
    public StubbedQueryBuilder buildStub() {
        this.stubbedQueryBuilder = new StubbedQueryBuilder(this);
        return this.stubbedQueryBuilder;
    }

    /**
     * Builds a current state of query and outputs it to the debug console.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder preview() {
        String logRecord = '\n============RESULTING QUERY============\n\n'
                + this.toString()
                + '\n\n=======================================\n';
        System.debug(logRecord);
        return this;
    }

    /**
     * Builds a current state of query, replacing all the fields with COUNT(Id),
     * exexutes it, and outputs the result to the debug console.
     *
     * @return this - current instance of QueryBuilder.class
     */
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

    /**
     * Nullifies and re-creates all of the fields in current QueryBuilder instance.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder newQuery() {
        this.fieldTokens = new Set<String>();
        this.groupByFields = new Set<String>();
        this.sortingOrder = new List<Order>();
        this.conditionsManager = new ConditionsManager(this);
        this.queryLimit = 0;
        this.queryOffset = 0;
        this.countResult = null;
        this.checkCrud = false;
        this.checkFls = false;
        this.updateTracking = false;
        this.updateViewstat = false;
        this.forView = false;
        this.forReference = false;
        this.withSecurityEnforced = false;
        this.scope = FilterScope.Everything;
        return this;
    }

    /**
     * Resets a result for current query.
     * Otherwise, each new call to toList() method returns the same result.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder resetResult() {
        this.result = null;
        return this;
    }

    /**
     * Builds a query based in current params.
     *
     * @return string representation of query
     */
    public override String toString() {
        String result = 'SELECT ';
        String fields = '';
        if (this.fieldTokens.isEmpty()) {
            fields = 'Id';
        } else {
            fields = String.join(new List<String>(this.fieldTokens), '\n\t, ');
        }
        result += fields + ' \n';
        result += 'FROM ' + this.fromSobject + ' \n';
        if (this.scope != FilterScope.Everything) {
            result += 'USING SCOPE ' + this.scope.name() + ' \n';
        }
        if (this.conditionsManager.hasConditions()) {
            result += 'WHERE ' + this.conditionsManager.builtCondition + ' \n';
        }
        if (this.withSecurityEnforced) {
            result += 'WITH SECURITY_ENFORCED \n';
        }

        if (!this.groupByFields.isEmpty()) {
            result += 'GROUP BY ';
            result += String.join(new List<String>(this.groupByFields), ', ') + ' \n';
        }
        if (!this.sortingOrder.isEmpty()) {
            result += 'ORDER BY ';
            List<String> orders = new List<String>();
            for (Order order : this.sortingOrder) {
                orders.add(order.toString());
            }
            result += String.join(orders, ', ') + ' \n';
        }
        if (this.queryLimit > 0) {
            result += 'LIMIT ' + this.queryLimit + ' \n';
        }
        if (this.queryOffset > 0) {
            result += 'OFFSET ' + this.queryOffset + ' \n';
        }

        if ((this.forView && !this.forReference) || (this.forView && this.forReference)) {
            result += 'FOR VIEW \n';
        }
        if (!this.forView && this.forReference) {
            result += 'FOR REFERENCE \n';
        }

        if (this.updateTracking && this.updateViewstat) {
            result += 'UPDATE TRACKING, VIEWSTAT';
        }
        if (this.updateTracking && !this.updateViewstat) {
            result += 'UPDATE TRACKING';
        }
        if (!this.updateTracking && this.updateViewstat) {
            result += 'UPDATE VIEWSTAT';
        }


        return result.trim();
    }

    /**
     * Builds a query, replacing all the selected fields with COUNT(Id)
     * and returns as a string.
     *
     * @return string representation of query with COUNT(ID) instead of fields
     */
    public String toStringCount() {
        String result = 'SELECT ';
        String countString = 'count() ';
        result += countString;
        result += 'FROM ' + this.fromSobject + ' ';
        if (this.conditionsManager.hasConditions()) {
            result += 'WHERE ' + this.conditionsManager.builtCondition + ' ';
        }
        if (this.scope != FilterScope.Everything) {
            result += 'USING SCOPE ' + this.scope.name() + ' ';
        }
        if (this.queryLimit > 0) {
            result += 'LIMIT ' + this.queryLimit + ' ';
        }
        if (this.queryOffset > 0) {
            result += 'OFFSET ' + this.queryOffset + ' ';
        }
        return result.trim();
    }

    /**
     * Builds a query, replacing all the selected fields with COUNT(Id),
     * executes it and returns a number of records.
     *
     * @return number of records
     */
    public Integer toCount() {
        if (this.countResult == null) {
            this.countResult = Database.countQuery(this.toStringCount());
        }
        return this.countResult;
    }

    /**
     * Executes a query or returns already executed result as a list of SObjects
     *
     * @return list of SObjects
     */
    public List<SObject> toList() {
        if (this.result == null) {
            List<SObject> result = Database.query(this.toString());
            SObjectReadValidator sObjectReadValidator;
            if (this.checkCrud || this.checkFls) {
                SObjectReadValidator = new SObjectReadValidator(result);
                if (this.checkCrud) {
                    sObjectReadValidator.checkObjectAccess();
                }
                if (this.checkFls) {
                    SObjectReadValidator.checkFieldsAccess();
                }
            }
            this.result = result;
        }
        return this.result;
    }

    /**
     * Executes a query or returns already executed result as a map of SObjects by Id
     *
     * @return map of SObjects by Id
     */
    public Map<Id, SObject> toMap() {
        return new Map<Id, SObject>(this.toList());
    }

    /**
     * Executes a query or returns already executed result and fills the max from params.
     *
     * @param mapToFill
     *
     * @return map of SObjects by Id
     */
    public Map<Id, SObject> toMap(Map<Id, SObject> mapToFill) {
        for (SObject sobj : this.toList()) {
            Id sobjId = (Id) sobj.get('Id');
            mapToFill.put(sobjId, sobj);
        }
        return mapToFill;
    }

    /**
     * Returns the first SObject from the query result.
     *
     * @return first SObject from query
     */
    public SObject toSObject() {
        List<SObject> result = this.toList();
        if (result.isEmpty()) {
            return null;
        }
        return result[0];
    }

    /**
     * Executes a query or returns already executed result as a set of Ids.
     *
     * @return set of Ids
     */
    public Set<Id> toIdSet() {
        return this.toMap().keySet();
    }

    /**
     * Builds a query string and returns a QueryLocator
     *
     * @return Database.QueryLocator built based on query
     */
    public Database.QueryLocator toQueryLocator() {
        return Database.getQueryLocator(this.toString());
    }

    /**
     * Executes a query or returns already executed result as a set of Ids extracted from fields of resulted SObjects.
     *
     * @param fieldName
     *
     * @return set of Ids from query
     */
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

    /**
     * Executes a query or returns already executed result as a list of Objects extracted from fields of resulted SObjects.
     *
     * @param fieldName - String name of a field
     *
     * @return list of Objects
     */
    public List<Object> extractField(String fieldName) {
        List<Object> result = new List<Object>();
        for (SObject sobj : this.toList()) {
            result.add(sobj.get(fieldName));
        }
        return result;
    }

    /**
     * Executes a query or returns already executed result as a list of Objects extracted from fields of resulted SObjects.
     *
     * @param fieldName - field in a form of SObjectField
     *
     * @return list of Objects
     */
    public List<Object> extractField(SObjectField field) {
        List<Object> result = new List<Object>();
        for (SObject sobj : this.toList()) {
            result.add(sobj.get(field));
        }
        return result;
    }

    /**
     * Clones a query builder. Doesn't clone the result list.
     *
     * @return new instance of QueryBuilder, based on current state
     */
    public QueryBuilder cloneQueryBuilder() {
        return this.cloneQueryBuilder(false);
    }

    /**
     * Clones a query builder. Can include the list of already queried records.
     *
     * @return new instance of QueryBuilder, based on current state
     */
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

    /**
     * Class, which allows building query conditions.
     *
     * @author github.com/4an70m
     * @version 1.0
     */
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
                conditions = conditions.replaceFirst(conditionNumber, this.bracket(conditionNumber));
            }
            return conditions;
        }

        private String bracket(String condition) {
            return this.BRACKET_L + condition.trim() + this.BRACKET_R;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     *
     * @author github.com/4an70m
     * @version 1.0
     */
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

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is field-dependent.
     *
     * @author github.com/4an70m
     * @version 1.0
     */
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

        public Condition lte(String fieldValue) {
            this.formedCondition = this.fieldName + ' <= ' + fieldValue;
            return this;
        }

        public Condition gte(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' >= ' + fieldValue;
            return this;
        }

        public Condition gte(String fieldValue) {
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

        public Condition notLikeAnyBoth(String fieldValue){
            this.formedCondition = ' (NOT ' + this.fieldName + ' LIKE ' + this.quote('%' + fieldValue + '%') + ')';
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

        public Condition inCollection(QueryBuilder queryBuilder) {
            this.formedCondition = this.fieldName + ' IN ' + this.bracket(queryBuilder.toString());
            return this;
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

        //set helpers
        private String buildIn(Set<String> inSet) {
            return this.bracket(
                    this.QUOTE
                            + String.join(new List<String> (inSet), this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildIn(Set<Id> inSet) {
            return this.bracket(
                    this.QUOTE
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

        public Condition inCollection(List<PicklistEntry> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            Set<String> picklistEntryValues = new Set<String>();
            for (PicklistEntry entry : inList) {
                picklistEntryValues.add(entry.value);
            }
            this.inCollection(picklistEntryValues);
            return this;
        }

        //list helpers
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
                return this;
            }
            this.formedCondition = this.fieldName + ' NOT IN ' + this.buildIn(inSet);
            return this;
        }

        public Condition notIn(Set<String> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' NOT IN ' + this.buildIn(inSet);
            return this;
        }

        public Condition notIn(List<String> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' NOT IN ' + this.buildIn(inList);
            return this;
        }

        public Condition notIn(QueryBuilder queryBuilder) {
            String builtSubQuery = queryBuilder.toString();
            if (String.isEmpty(builtSubQuery)) {
                this.formedCondition = '';
                return this;
            }
            this.formedCondition = this.fieldName + ' IN ' + this.bracket(builtSubQuery);
            return this;
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

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is Object-type dependent.
     *
     * @author github.com/4an70m
     * @version 1.0
     */
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

    /**
     * Virtual class for creating Order in Query.
     *
     * @author github.com/4an70m
     * @version 1.0
     */
    public virtual class Order {

        private final String sortingField;
        private String sortingOrder;
        private String nullsOrder;

        protected Order(String sortingField, String sortingOrder, String nullsOrder) {
            this.sortingField = sortingField;
            this.sortingOrder = sortingOrder;
            this.nullsOrder = nullsOrder;
        }

        protected Order(String sortingField, String sortingOrder) {
            this(sortingField, sortingOrder, '');
        }

        public Order(String sortingField) {
            this(sortingField, 'ASC', '');
        }

        public Order(SObjectField sortingField) {
            this(sortingField.getDescribe().getName());
        }

        public Order setSortingOrder(String sortingOrder) {
            this.sortingOrder = sortingOrder;
            return this;
        }

        public Order setSortingOrderAsc() {
            return this.setSortingOrder('ASC');
        }

        public Order setSortingOrderDesc() {
            return this.setSortingOrder('DESC');
        }

        public Order setNullsOrder(String nullsOrder) {
            this.nullsOrder = nullsOrder;
            return this;
        }

        public Order setNullsOrderFirst() {
            return this.setNullsOrder('FIRST');
        }

        public Order setNullsOrderLast() {
            return this.setNullsOrder('LAST');
        }

        public override String toString() {
            return this.sortingField
                    + ' ' + this.sortingOrder
                    + (String.isNotEmpty(this.nullsOrder) ? ' NULLS ' + this.nullsOrder : '');
        }
    }

    /**
     * Class for ordering records Ascending.
     *
     * @author github.com/4an70m
     * @version 1.0
     */
    public class AscOrder extends Order {

        public AscOrder(String sortingField) {
            super(sortingField, 'ASC');
        }
    }

    /**
     * Class for ordering records Descending.
     *
     * @author github.com/4an70m
     * @version 1.0
     */
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

    public class StubbedQueryBuilder extends QueryBuilder {

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

    /**
     * Class, which performs validation of list of SObjects.
     * Can check CRUD and FLS.
     *
     * @author github.com/4an70m
     * @version 1.0
     */
    public class SObjectReadValidator {

        private List<SObject> sObjectsToValidate;
        private SObjectType sObjectType;
        private DescribeSObjectResult describedSObjectType;

        public SObjectReadValidator(List<SObject> sObjectsToValidate) {
            this.sObjectsToValidate = sObjectsToValidate;
            this.sObjectType = sObjectsToValidate.getSObjectType();
            this.describedSObjectType = this.sObjectType.getDescribe();
        }

        public void validate() {
            this.checkObjectAccess();
            this.checkFieldsAccess();
        }

        public void checkObjectAccess() {
            if (!this.describedSObjectType.isAccessible() || !this.describedSObjectType.isQueryable()) {
                throw new System.NoAccessException();
            }
        }

        public void checkFieldsAccess() {
            Map<String, SObjectField> sobjectFields = this.describedSObjectType.fields.getMap();
            Map<String, ChildRelationship> childRelationshipsByName = this.getChildRelationshipsByName(describedSObjectType);
            for (SObject sobj : this.sObjectsToValidate) {
                this.validateSobject(sobj, sobjectFields, childRelationshipsByName);
            }
        }

        private void validateSobject(SObject sobj, Map<String, SObjectField> sobjectFields, Map<String, ChildRelationship> childRelationshipsByName) {
            Map<String, Object> sobjectPopulatedFields = sobj.getPopulatedFieldsAsMap();
            for (String fieldName : sobjectPopulatedFields.keySet()) {
                SObjectField sobjectField = sobjectFields.get(fieldName);
                if (sobjectField == null) {
                    ChildRelationship childRelationship = childRelationshipsByName.get(fieldName);
                    if (childRelationship == null) {
                        System.debug('FLS Validator: No child relationship: ' + fieldName);
                        continue;
                    }
                    new SObjectReadValidator(sobj.getSObjects(fieldName)).validate();
                    continue;
                } else if (!sobjectField.getDescribe().isAccessible()) {
                    System.debug('FLS Validator: Not accessible field: ' + fieldName);
                    sobj.put(sobjectField, null);
                    continue;
                }
            }
        }

        private Map<String, ChildRelationship> getChildRelationshipsByName(DescribeSObjectResult describedSObjectType) {
            Map<String, ChildRelationship> result = new Map<String, ChildRelationship>();
            List<ChildRelationship> childRelationships = describedSObjectType.getChildRelationships();
            for (ChildRelationship childRelationship : childRelationships) {
                result.put(childRelationship.getRelationshipName(), childRelationship);
            }
            return result;
        }
    }

    public class QueryBuilderException extends Exception {
    }
}