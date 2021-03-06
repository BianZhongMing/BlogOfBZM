--透视，逆透视，分组集 pivoting ,unpivoting ,grouping set

---------------基本数据
use tempdb
go

if(object_id('dbo.asktom') is not null ) drop table asktom;
create table asktom(
id int not null identity(1,1),
adate date not null,
localid int not null,
refid varchar(10) not null,
val int not null
constraint pk_asktom primary key(id)
);

insert into asktom(adate,localid,refid,val) values
('20170101',1,'A',10),
('20170103',2,'A',12),
('20170102',3,'B',15),
('20170101',3,'C',14),
('20170105',2,'A',11),
('20170105',1,'B',12),
('20170107',1,'C',13),
('20170106',2,'D',15),
('20170106',2,'B',18),
('20170106',3,'B',19);

select * from asktom;

------------透视（按照localid和refid）
--ANSI SQL 实现
select localid,
sum(case refid when 'A' then val end) as A, --不写else 默认else NULL，聚合函数除count忽略NULL
sum(case refid when 'B' then val end) as B,
sum(case refid when 'C' then val end) as C,
sum(case refid when 'D' then val end) as D
from asktom 
group by localid;
--pivot 实现(分组--扩展--聚合)
select localid,A,B,C,D 
from(select localid,refid,val from asktom/*把分组,扩展,聚合需要的列都包含进来*/) as D
pivot(sum(val) for refid in(A,B,C,D)) AS P;
--优势：快速实现聚合列的变更
select refid,"1","2","3" 
from(select localid,refid,val from asktom/*把分组,扩展,聚合需要的列都包含进来*/) as D
pivot(sum(val) for localid in("1","2","3")) AS P;


------------逆透视
--Basic Data
select localid,A,B,C,D into asktomU
from(select localid,refid,val from asktom/*把分组,扩展,聚合需要的列都包含进来*/) as D
pivot(sum(val) for refid in(A,B,C,D)) AS P;
--ANSI SQL 实现
select localid,refid,val
from(
select localid,refid,case refid when 'A' then A 
when 'B' then B when 'C' then C when 'D' then D end as val from asktomU
cross join (values('A'),('B'),('C'),('D')) as element(refid)
) as D
where val is not null
--透视-逆透视 是不可逆运算（存在数据丢失）
--unpivot实现（生成副本--提取元素--去除交叉位置上的NULL）
select localid,refid,val from asktomU
unpivot(val for refid in(A,B,C,D)) AS U;

--分组集（grouping set）
SELECT   adate, localid, sum(val) AS sumval
FROM     asktom
GROUP BY adate, localid
union all
SELECT   adate, NULL localid, sum(val) AS sumval
FROM     asktom
GROUP BY adate
union all
SELECT   NULL adate, localid, sum(val) AS sumval
FROM     asktom
GROUP BY localid
union all
SELECT NULL adate, NULL localid, sum(val) AS sumval FROM asktom;
--等价分组集(提升性能<减少表扫描次数>，精简代码)
SELECT   adate, localid, sum(val) AS sumval
FROM     asktom
GROUP BY 
 grouping sets(
 (adate, localid),(localid),(adate),());


------Other usage of grouping set
--1.等价cube子句(构造power set<幂集>),精简代码，执行效率和grouping sets一致
--cube(a,b,c)等价：grouping sets((a,b,c),(a,b),(a,c),(b,c),(a),(b),(c),())
SELECT   adate, localid, sum(val) AS sumval
FROM     asktom
GROUP BY cube(adate, localid)--old usage:GROUP BY adate, localid with cube
;
--2.rollup子句(生成层次grouping sets)
--rollup(a,b,c):a>b>c;[equal]grouping set((a,b,c),(a,b),(a),());*/
SELECT year (adate) AS Y,
       month (adate) M,
       day (adate) D,
       sum (val) AS sumval
  FROM asktom
GROUP BY ROLLUP (year (adate), month (adate), day (adate))
--old usage:GROUP BY year (adate), month (adate), day (adate) with rollup
;

--3.grouping函数:判断该列是不是当前分组集的元素
--特别是字段可以为空的时候需要区分是原始数据还是占位符NULL
--note:  是：返回0，不是：返回1
SELECT grouping (adate) Gadate,
       grouping (localid) Glocalid,
       adate,
       localid,
       sum (val) AS sumval
  FROM asktom
GROUP BY CUBE (adate, localid);
--grouping_id:返回integer bitmap（整数位图）
--grouping_id(a,b,c)=grouping(a)*2^2+grouping(b)*2^1+grouping(c)*2^0
--note:是分组成员：0，不是分组：1
SELECT grouping_id (adate,localid) intBitmap,
       adate,
       localid,
       sum (val) AS sumval
  FROM asktom
GROUP BY CUBE (adate, localid);

