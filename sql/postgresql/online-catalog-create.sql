-- online-catalog-create.sql
--
-- @author Dekka Corp.
-- @license GNU GENERAL PUBLIC LICENSE, Version 2, June 1991
-- @cvs-id
--

-- porting from ecommerce
-- product display templates
-- for more generic use

-- create sequence ec_template_id_seq start 2;
create sequence ecca_template_id_seq start 2;

-- create view ec_template_id_sequence as select nextval('ec_template_id_seq') as nextval;
create view ecca_ec_template_id_sequence as select nextval('ecca_ec_template_id_seq') as nextval;


-- I should have named this product_templates because now we
-- have other kinds of templates.

create table ecca_ec_templates (
        template_id             integer not null primary key,
        template_name           varchar(200),
        template                varchar(4000),
        last_modified           timestamptz not null,
        last_modifying_user     integer not null references users,
        modified_ip_address     varchar(20) not null
);

create table ecca_ec_templates_audit (
        template_id             integer,
        template_name           varchar(200),
        template                varchar(4000),
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        delete_p                boolean default 'f'
);

-- A trigger is used to move information from the main table to 
-- the audit table
create function ecca_ec_templates_audit_tr () 
returns opaque as '
begin
        insert into ecca_ec_templates_audit (
        template_id, template_name,
        template,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.template_id,
        old.template_name, old.template,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address      
        );
	return new;
end;' language 'plpgsql';

create trigger ecca_ec_templates_audit_tr
after update or delete on ecca_ec_templates
for each row execute procedure ecca_ec_templates_audit_tr ();



-- This inserts the default template into the ecca_ec_templates table
insert into ecca_ec_templates (
        template_id, template_name, template,
        last_modified, last_modifying_user, modified_ip_address
        ) values (
        1,'Default',
        '<h2><%= $product_name %></h2>' || '\n'  || '\n'
        || '<table width=100%>' || '\n'
        || '<tr>' || '\n'
        || '<td>' || '\n'
        || ' <table>' || '\n'
        || ' <tr>' || '\n'
        || ' <td><%= [ecca_ec_linked_thumbnail_if_it_exists $dirname] %></td>' || '\n'
        || ' <td>' || '\n'
        ||     ' <b><%= $one_line_description %></b>' || '\n'
        ||     ' <br>' || '\n'
        ||     ' <%= [qar_ec_price_line $product_id $user_id $offer_code] %>' || '\n'
        || ' </td>' || '\n'
        || ' </tr>' || '\n'
        || ' </table>' || '\n'
        || '</td>' || '\n'
        || '<td align=center>' || '\n' || '<%= [qar_ec_add_to_cart_link $product_id] %>' || '\n' || '</td>' || '\n'
        || '</tr>' || '\n'
        || '</table>' || '\n' || '\n'
        || '<p>' || '\n'
        || '<%= $detailed_description %>' || '\n' || '\n'
        || ' <%= [qci_ec_product_link_if_exists $product_id] %>' || '\n'
        || ' <br>' || '\n'
        || '<%= [qar_ec_display_product_purchase_combinations $product_id] %>' || '\n' || '\n'
        || '<%= [qci_ec_product_links_if_they_exist $product_id] %>' || '\n' || '\n'
        || '<%= [qci_ec_professional_reviews_if_they_exist $product_id] %>' || '\n' || '\n'
        || '<%= [qar_ec_customer_comments $product_id $comments_sort_by] %>' || '\n' || '\n'
        || '<p>' || '\n' || '\n'
        || '<%= [qar_ec_mailing_list_link_for_a_product $product_id] %>' || '\n' || '\n',
        now(), (select grantee_id
                    from acs_permissions
                   where object_id = acs__magic_object_id('security_context_root')
                     and privilege = 'admin'
                     limit 1),
        'none');


