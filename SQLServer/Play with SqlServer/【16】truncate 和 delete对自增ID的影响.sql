if(object_id('dbo.testa') is not null) drop table testa;
go
create table testa(id bigint not null primary key identity(1,1) ,tname nvarchar(max) );
--3 Times
insert into testa(tname) values(N'ddcawsdqwedf'),(N'ddcawsdqwedf'),(N'ddcawsdqwedf');

select max(id) from testa; --9

truncate table testa;

insert into testa(tname) values(N'ddcawsdqwedf'),(N'ddcawsdqwedf'),(N'ddcawsdqwedf');

select max(id) from testa; --3

delete from testa where id<=3;

insert into testa(tname) values(N'ddcawsdqwedf'),(N'ddcawsdqwedf'),(N'ddcawsdqwedf');

select max(id) from testa; --6

--重置identity seed（新加入的值=seed+step）
DBCC CHECKIDENT ('testa', RESEED, 0)

drop table testa;

