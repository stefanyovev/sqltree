# new, drop
# set, get
# up, down
# move
# list

create database reg default character set ucs2;

use reg;

create table `t` (
	`node`	varchar(500) not null primary key default '',
	`depth`	int unsigned not null default 1,
	`pos`	int unsigned not null default 1,
	`value`	varchar(500) not null default ''
);

delimiter //

create procedure tNew ( aNode varchar(500), aValue varchar(500) )
begin
	declare newPos int unsigned default 1;
	declare cNode varchar(300) default '';
	declare n int unsigned default 1;
	while cNode <> aNode do
		set cNode = substring_index( aNode, '/', n );
		if not exists ( select `node` from `t` where `node` = cNode ) then
			select max(pos)+1 into newPos from `t` where
				node like concat( substring_index( cNode, '/', n ), '/%' )
				and depth = n;
			set newPos = if( newPos < 1 or newPos is null, 1, newPos );
			insert into `t` values ( cNode, n, newPos, '' );
		end if;
		set n = n + 1;
	end while;
	update `t` set value = aValue where node = aNode;
end

//

create procedure tDrop ( aNode varchar(500) ) begin
delete from `t`	where node = aNode
or node like concat( aNode, '/%' ); end

//

create procedure tSet ( aNode varchar(500), aValue varchar(500) ) begin
update `t` set value = aValue where node = aNode; end

//

create procedure tGet ( aNode varchar(500) ) begin
select value from `t` where node = aNode; end

//

create procedure tList ( aNode varchar(500) )
begin
	declare cDepth int unsigned default 0;
	select depth into cDepth from `t` where node = aNode;
	select substring_index( node, '/', -1 ) as 'items' from `t`
		where node like concat( aNode, '/%' )
		and depth = cDepth + 1;
end
