CREATE TABLE customers (
    id           text PRIMARY KEY,
    name         text,
    segment      text,           -- Consumer / Corporate / Home Office
    country      text,
    city         text,
    state        text,
    postal_code  text,
    region       text            -- East / West / Central / South
);

CREATE TABLE employees (
    id_employee  int PRIMARY KEY,
    name         text,
    city         text,
    region       text            -- employee region
);

CREATE TABLE product (
    product_id      text PRIMARY KEY,
    category_group  text,        -- Furniture / Technology / Office Supplies
    subcategory     text,        -- Chairs / Phones / Paper / Tables / ...
    product_name    text
);

CREATE TABLE orders (
    row_id       int PRIMARY KEY,
    order_id     text,
    order_date   date,
    ship_date    date,
    ship_mode    text,
    customer_id  text REFERENCES customers(id),
    product_id   text REFERENCES product(product_id),
    sales        numeric,
    quantity     int,
    discount     numeric,
    profit       numeric,
    id_employee  int REFERENCES employees(id_employee)
);
