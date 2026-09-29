# Report 362

Production defect in inventory_voucher_report was fixed by adding GROUP BY v.type and GROUP BY v.status. LIST and SUMMARY were verified with an authenticated tenant context and rolled back transactionally. No frontend file was modified.
