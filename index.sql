-- Indexes to speed up common queries (e.g., filtering by equipment, company, or dates)
CREATE INDEX idx_equipment_parent       ON equipment(parent_id);
CREATE INDEX idx_rental_equipment_date ON rental(equipment_id, rental_start);
CREATE INDEX idx_rental_company_date   ON rental(company_location_id, rental_start);
CREATE INDEX idx_rental_start          ON rental(rental_start);
CREATE INDEX idx_maintenance_equip_date ON maintenance(equipment_id, maintenance_date);
CREATE INDEX idx_company_location_company ON company_location(company_id);
