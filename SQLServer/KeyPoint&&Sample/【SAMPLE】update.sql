-- update demo
--BASIC DATA
use tempdb;
GO

if(object_id('torder','U') is not null) drop table torder;
create table torder(
id bigint not null identity(1,1) constraint PK_TORDER primary key,
onumb varchar(10) not null,
odetailnumb varchar(20) not null,
val1 decimal(20,8),
val2 decimal(20,8),
constraint UN_TORDER  unique nonclustered(onumb)   
);

if(object_id('torderUp','U') is not null) drop table torderUp
create table torderUp(
id bigint not null identity(1,1) constraint PK_torderUp primary key,
onumb varchar(10) not null,
odetailnumb varchar(20) not null,
val1 decimal(20,8)
constraint UN_torderUp  unique nonclustered(onumb)   
);

insert into torder (onumb,odetailnumb,val1,val2) values 
('111','AAAAAAAA',10.5,15.5),('222','2222222222',20.5,25.5);
insert into torderUp (onumb,odetailnumb,val1) values 
('111','AAAAAAAA',11.11),('222','BBBBBBBBB',12.22);


select * from torder a join torderUp b on a.onumb=b.onumb

--复合赋值运算符更新（+=，-+，*=，/=,%=）
update torder set val2+=100; --val2=val2+100
/* select * from torder;
id	onumb	odetailnumb	val1	val2
1	111	AAAAAAAA	10.50000000	115.50000000
2	222	2222222222	20.50000000	125.50000000
*/

--update/select 时的 all-at-once operation
UPDATE torder set val1+=10000,val2+=val1;
--val2 update时取的val1是没有update之前的值
/* select * from torder;
id	onumb	odetailnumb	val1	val2
1	111	AAAAAAAA	10010.50000000	126.00000000
2	222	2222222222	10020.50000000	146.00000000
*/
--应用:互相赋值(不需要借助中间变量)
UPDATE torder set val1=val2,val2=val1;
/* select * from torder;
id	onumb	odetailnumb	val1	val2
1	111	AAAAAAAA	126.00000000	10010.50000000
2	222	2222222222	146.00000000	10020.50000000
*/

--cascade update(NOT ANSI standard)
UPDATE a
   SET odetailnumb = b.odetailnumb,val1=b.val1
  FROM torder a JOIN torderUp b ON a.onumb = b.onumb;
/* select * from torder;
*/
--某些情况下,级联比子查询效率高
/*
更新/删除方式选择原则：
step 1.选择效率高的
step 2.相同效率选择兼容性强的（ANSI SQL）
*/
--ANSI SQL 改写
UPDATE torder
   SET odetailnumb =
          (SELECT b.odetailnumb
             FROM torderUp b
            WHERE torder.onumb = b.onumb),
       val1 =
          (SELECT b.val1
             FROM torderUp b
            WHERE torder.onumb = b.onumb)
 WHERE EXISTS
          (SELECT 1
             FROM torderUp b
            WHERE torder.onumb = b.onumb);
--OR
UPDATE a
   SET odetailnumb =
          (SELECT b.odetailnumb
             FROM torderUp b
            WHERE a.onumb = b.onumb),
       val1 =
          (SELECT b.val1
             FROM torderUp b
            WHERE a.onumb = b.onumb)
  FROM torder a /* 表别名 */
 WHERE EXISTS
          (SELECT 1
             FROM torderUp b
            WHERE a.onumb = b.onumb);

--set+update
declare @t decimal(20,8)=NULL;
update torder set @t=val1=val2+1; --set 从右往左执行
select @t;
/*优势:update 原子性操作,更新和赋值在一个操作中,比update+set效率高
 注意:涉及多行数据更新时,变量留下的是最后的一个数据*/


-----------------通过表表达式修改数据
--使用：特定场景，逻辑清晰
------cascade update
begin tran;
UPDATE a
   SET odetailnumb = b.odetailnumb,val1=b.val1
  FROM torder a JOIN torderUp b ON a.onumb = b.onumb;
  
select * FROM torder a JOIN torderUp b ON a.onumb = b.onumb;  
rollback;
-------等价CTE 更新
begin tran;

;with CTE as 
(select a.odetailnumb, b.odetailnumb as odNew, a.val1, b.val1 as val1New
FROM   torder a JOIN torderUp b ON a.onumb = b.onumb)
update cte set odetailnumb=odNew,val1=val1New;

select * FROM torder a JOIN torderUp b ON a.onumb = b.onumb;  
rollback;
-------等价派生表更新
update D set odetailnumb=odNew,val1=val1New
from (select a.odetailnumb, b.odetailnumb as odNew, a.val1, b.val1 as val1New
FROM   torder a JOIN torderUp b ON a.onumb = b.onumb) AS D;
--【特性】更新序列数据（表表达式简介高效）
/*update 的set子句不允许包含 row_number函数*/
update D set onumb=rn
from 
(select onumb,row_number() over(order by (select 1)) as rn from torder) as D;
select * from torder;

drop table torder;
drop table torderup;

--------------通过top 修改数据
--生成随机字符串
select t*10+o col ,newid() id into tnum
from 
(values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) as D(t)
cross join (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) as E(o);
--生成随机排列数字
update D set col=numb 
from(select col,id,row_number() over(order by id) numb from tnum) as D ;
--直接update top 50 tablename/delete top 50 from tablename 是随机变更数据
--top order指定数据变更，利用表表达式
update D set id=NULL from (
select top 10 col,id from tnum order by col) AS D;
--clear
select * from tnum order by col;
drop table tnum;
