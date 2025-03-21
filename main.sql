-- Company: client companies renting equipment
CREATE TABLE company (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL  -- Company name
    -- (Additional fields like contact info can be added as needed)
);

-- CompanyLocation: different operational locations/offices for each company
CREATE TABLE company_location (
    id SERIAL PRIMARY KEY,
    company_id INT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    location_name VARCHAR(100) NOT NULL,       -- e.g., branch name or site identifier
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50)
    -- Optionally ensure unique location names per company:
    -- , CONSTRAINT uniq_location_name_per_company UNIQUE(company_id, location_name)
);

-- Equipment: individual equipment units (with possible sub-units)
CREATE TABLE equipment (
    id SERIAL PRIMARY KEY,
    equipment_type VARCHAR(50) NOT NULL,       -- Category/type (e.g., Excavator, Bulldozer, Truck)
    model VARCHAR(100) NOT NULL,              -- Model name/number (or description)
    serial_number VARCHAR(50) UNIQUE,         -- Serial number (unique if provided)
    license_plate VARCHAR(20) UNIQUE,         -- License plate (unique if provided, for vehicles)
    parent_id INT REFERENCES equipment(id),    -- Self-reference for hierarchical structure (sub-equipment)
    CONSTRAINT serial_or_plate_chk CHECK (
        serial_number IS NOT NULL OR license_plate IS NOT NULL
    )  -- Ensure at least one identifier is provided
);

-- Rental: records of equipment rentals to clients
CREATE TABLE rental (
    id SERIAL PRIMARY KEY,
    equipment_id INT NOT NULL REFERENCES equipment(id),           -- Rented equipment unit
    company_location_id INT NOT NULL REFERENCES company_location(id),  -- Renting client location (and implicitly company)
    rental_start TIMESTAMP NOT NULL,    -- Date and time equipment was rented out
    rental_end TIMESTAMP,              -- Date and time returned (NULL if not yet returned)
    rate NUMERIC(10,2) NOT NULL,       -- Rental rate (per hour or per day)
    rate_unit VARCHAR(10) NOT NULL CHECK (rate_unit IN ('Hourly','Daily')),  -- Rate basis
    quantity_used NUMERIC(10,2) NOT NULL   -- Hours or days used (interpret based on rate_unit)
    -- Optionally, a computed total cost could be stored (rate * quantity_used)
);

-- MechanicShop: external maintenance providers
CREATE TABLE mechanic_shop (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,   -- Mechanic shop name
    phone VARCHAR(20),           -- Contact phone number
    address VARCHAR(200)         -- Address or location of the shop
);

-- Employee: internal employees (e.g., mechanics) who perform maintenance
CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    position VARCHAR(50)         -- Job title or role (e.g., Mechanic)
);

-- Maintenance: maintenance and repair logs for equipment
CREATE TABLE maintenance (
    id SERIAL PRIMARY KEY,
    equipment_id INT NOT NULL REFERENCES equipment(id),    -- Equipment that was serviced
    maintenance_date DATE NOT NULL,                        -- Date of maintenance
    description TEXT NOT NULL,                             -- Description of the maintenance work
    cost NUMERIC(10,2) NOT NULL,                           -- Cost of the maintenance
    mechanic_shop_id INT REFERENCES mechanic_shop(id),
    employee_id INT REFERENCES employee(id),
    invoice_file BYTEA,    -- Invoice document (binary data, e.g., PDF or image)
    CONSTRAINT maintenance_provider_chk CHECK (
        (mechanic_shop_id IS NOT NULL AND employee_id IS NULL)
        OR (mechanic_shop_id IS NULL AND employee_id IS NOT NULL)
    )  -- Either an external shop OR an internal employee must be associated
);
