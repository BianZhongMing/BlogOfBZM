--集合运算（结果不一定是集合<可能存在重复行>，可能是多集）
--基础数据
if(object_id('dbo.testa','U') is not null) drop table testa;
GO
create table testa 
(id int not null,
tname varchar(50) NULL);

if(object_id('dbo.testb','U') is not null) drop table testb;
GO
create table testb 
(id int not null,
tname varchar(50) NULL);

insert into testa values(1,'XM'),(2,NULL),(3,'XH'),(3,'XH'),(3,'XB');
insert into testb values(1,'XM'),(1,'XM'),(2,NULL),(3,'XH'),(4,'XB');

select * from testa;
select * from testb;

--------------------集合的排序
select id,tname from testa
order by tname --报错，表是集合，集合无序
union all
select id,tname from testb;

select id,tname from testa
union all
(select id,tname from testb order by tname) --报错，表是集合，集合无序
;

select id,tname from testa
union all
select id,tname from testb order by tname;
--这个集合可以排序输出，最后的order基于整个查询所以可以执行。
--优先级顺序：查询->集合运算->ORDER  

--------------------集合运算的前提条件
select id,tname pname from testa
union all
select count(1),tname from testb group by tname
--1.列数相同
--2.格式可转

--------------------集合运算的共同规律
--1.列名前定（列名由第一个查询确定）
--2.只提供两选项支持(DISTINCT/ALL),default:DISTINCT,ALL需要显式指定

--------------------交
--简单交集
select id,tname from testa
union all
select id,tname from testb;
--去重
select id,tname from testa
union
select id,tname from testb;
--UNION=(first)UNION ALL+DISTINCT
--【三值】集合计算认为NULL相等

--------------------并
--去重
select id,tname from testa
intersect
select id,tname from testb;

--简单并集(间接实现,不完全)
select row_number() over(partition by id,tname order by (select 1) ) tid, id,tname from testa
intersect
select row_number() over(partition by id,tname order by (select 1) ) tid, id,tname from testb

--join改写
select distinct a.* from testa a join testb b on (a.id=b.id and isnull(a.tname,'')=isnull(b.tname,''));

--exists 改写
select distinct a.* from testa a
where exists(select 1 from testb b where a.id=b.id and isnull(a.tname,'')=isnull(b.tname,''));

--注意集合运算的三值逻辑(NULL=NULL)

--------------------差
--去重
--有序性（前面-后面）
select id,tname from testa
except
select id,tname from testb;

--outer join 改写
select distinct a.* from testa a left join testb b on (a.id=b.id and isnull(a.tname,'')=isnull(b.tname,''))
where b.id is null

--not exists 改写
select distinct a.* from testa a where not exists (
select 1 from testb b where a.id=b.id and isnull(a.tname,'')=isnull(b.tname,'') )

--------------------优先级:intersect>union=except
select 1 id 
union all
select 2 
except
select 2
intersect
select 1
--Step 1
select 2
intersect
select 1  --NULL
--step 2
select 1 id 
union all
select 2 --1/2
--step 3
select id from (values (1),(2)) as D(id)
except
select NULL


--------------------绕过只提供两选项支持（表表达式）
select tname,count(1) from (
(select top 1 * from testa order by tname)
union all
(select top 2 * from testb order by tname)
) as D
group by tname;

