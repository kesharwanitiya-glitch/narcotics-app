const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
    host: process.env.MYSQLHOST,
    port: process.env.MYSQLPORT,
    user: process.env.MYSQLUSER,
    password: process.env.MYSQLPASSWORD,
    database: process.env.MYSQLDATABASE
});

db.connect((err) => {
    if (err) console.log("DB Connection Failed:", err);
    else console.log("Connected to MySQL Database");
});

// --- AUTHENTICATION ---
app.post('/register', async (req, res) => {
    const { name, email, phone, password, role, license_no, gtin, shop_name, address } = req.body; 
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const query = "INSERT INTO users (full_name, email, password, role, drug_license_no, gstin, shop_name, address, phone_no) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        const finalLicense = license_no ?? "";
        const finalGtin = gtin ?? "";

        db.query(
            query, 
            [name, email, hashedPassword, role, finalLicense, finalGtin, shop_name, address, phone], 
            (err) => {
                if (err) {
                    console.error("❌ Database Insert Error:", err); 
                    return res.status(500).json({ message: "Error in Registration" });
                }
                res.status(200).json({ message: "User Registered Successfully!" });
            }
        );
    } catch (err) { 
        console.error("❌ Server Catch Error:", err);
        res.status(500).json({ message: "Internal Server Error" }); 
    }
});

app.post('/login', (req, res) => {
    const { email, password } = req.body;
    db.query("SELECT * FROM users WHERE email = ?", [email], async (err, results) => {
        if (err || results.length === 0) return res.status(404).json({ message: "User not found!" });
        const isMatch = await bcrypt.compare(password, results[0].password);
        if (isMatch) res.status(200).json({ message: "Login Successful", user: { id: results[0].id, name: results[0].full_name, role: results[0].role, gstin: results[0].gstin,
      email: results[0].email,  drug_license_no: results[0].drug_license_no,  phone_no: results[0].phone_no} });
        else res.status(401).json({ message: "Invalid Password!" });
    });
});

// --- WHOLESALER INWARD ---
app.post('/add-inward-stock', (req, res) => {
    const { drug_name, batch_no, expiry_date, quantity, owner_id, owner_email, gtin_code, manufacturer_name, mfg_license_no, received_date } = req.body;
    const query = `INSERT INTO inventory (drug_name, batch_no, expiry_date, quantity, owner_id, owner_email, gtin_code, manufacturer_name, mfg_license_no, received_date, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'In-Stock')`;
    db.query(query, [drug_name, batch_no, expiry_date, quantity, owner_id, owner_email, gtin_code, manufacturer_name, mfg_license_no, received_date], (err) => {
        if (err) return res.status(500).json({ error: err });
        res.status(200).json({ message: "Stock Added Successfully!" });
    });
});

app.get('/get-inward-history/:ownerId', (req, res) => {

    const ownerId = req.params.ownerId;

    const query = `
        SELECT *
        FROM inventory
        WHERE owner_id = ?
        AND status='In-Stock'
        ORDER BY id DESC
    `;

    db.query(query,[ownerId],(err,results)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.status(200).json(results);

    });

});

app.get('/get-auditable-stock/:ownerId', (req,res)=>{

    const ownerId=req.params.ownerId;

    const query=`
    SELECT
        drug_name,
        batch_no,
        SUM(quantity) as total_qty,
        MAX(expiry_date) as expiry_date
    FROM inventory
    WHERE owner_id=?
    GROUP BY drug_name,batch_no
    `;

    db.query(query,[ownerId],(err,results)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.status(200).json(results);

    });

});

// --- WHOLESALER OUTWARD ---
app.get('/get-retailers', (req, res) => {
    db.query("SELECT full_name, drug_license_no, shop_name FROM users WHERE role = 'Retailer'", (err, results) => {
        if (err) return res.status(500).json(err);
        res.status(200).json(results);
    });
});

// index.js - Is route ko update karo
app.post('/add-outward-transaction', (req, res) => {

    const {
        wholesaler_id,
        wholesaler_name,
        wholesaler_gstin,
        wholesaler_license,
        retailer_name,
        retailer_license,
        drug_name,
        batch_no,
        quantity,
        sale_date,
        expiry_date,
        gtin_code,
        shop_name
    } = req.body;

    console.log("Saving Transaction:", {
        wholesaler_name,
        wholesaler_gstin,
        expiry_date,
        gtin_code
    });

    const query = `
    INSERT INTO transactions (
        wholesaler_id,
        wholesaler_name,
        wholesaler_gstin,
        wholesaler_license,
        retailer_name,
        retailer_license,
        drug_name,
        batch_no,
        quantity,
        sale_date,
        status,
        expiry_date,
        gtin_code,
        shop_name
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', ?, ?, ?)
    `;

    db.query(
        query,
        [
            wholesaler_id,
            wholesaler_name,
            wholesaler_gstin,
             wholesaler_license,
            retailer_name,
            retailer_license,
            drug_name,
            batch_no,
            quantity,
            sale_date,
            expiry_date || null,
            gtin_code || null,
              shop_name || null
        ],
        (err) => {
            if (err) {
                console.error("❌ SQL Error:", err);
                return res.status(500).json(err);
            }

            res.status(200).json({
                message: "Invoice Sent!"
            });
        }
    );
});

app.get('/get-outward-history/:ownerId', (req, res) => {

    const ownerId = req.params.ownerId;

    const query = `
        SELECT *
        FROM transactions
        WHERE wholesaler_id = ?
        ORDER BY id DESC
    `;

    db.query(query,[ownerId],(err,results)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.status(200).json(results);

    });

});

// --- RETAILER FETCH ROUTES ---
app.get('/get-pending-invoices/:retailerName', (req, res) => {
    db.query("SELECT * FROM transactions WHERE retailer_name = ? AND status = 'Pending'", [req.params.retailerName], (err, results) => {
        res.status(200).json(results);
    });
});

// --- RETAILER ACCEPTANCE & AUTOMATIC DEDUCTION ---
// --- RETAILER ACCEPTANCE & AUTOMATIC DEDUCTION (COMPLETE FIXED FLOW) ---
app.post('/accept-invoice', (req, res) => {
    console.log("📥 Received Invoice Acceptance Request:", req.body);
    const { transaction_id, drug_name, batch_no, quantity, retailer_name } = req.body;
    
    // Step 1: Pehle transaction se expiry aur GTIN fetch karo
    const fetchDetailsQuery = "SELECT expiry_date, gtin_code,  wholesaler_id FROM transactions WHERE id = ?";
    
    db.query(fetchDetailsQuery, [transaction_id], (err, transData) => {
        if (err) {
            console.error("❌ SQL Error (Fetch):", err);
            return res.status(500).json({ error: "Database error during fetch" });
        }
        if (transData.length === 0) {
            console.warn("⚠️ Transaction not found for ID:", transaction_id);
            return res.status(404).json({ error: "Transaction not found" });
        }
        
        const { expiry_date, gtin_code, wholesaler_id } = transData[0];

        // Step 2: Transaction status ko 'Accepted' karo
        db.query("UPDATE transactions SET status = 'Accepted', received_date = NOW() WHERE id = ?", [transaction_id], (err) => {
            if (err) {
                console.error("❌ SQL Error (Update Status):", err);
                return res.status(500).json({ error: "History Update Failed" });
            }

            // Step 3: Inventory (Wholesaler side) mein Deduction entry daalo
            const insertDeductQuery = `INSERT INTO inventory (drug_name, batch_no, quantity, owner_id, status, received_date, expiry_date, gtin_code) VALUES (?, ?, ?, ?, 'Deducted', NOW(), ?, ?)`;
            db.query(insertDeductQuery, [drug_name, batch_no, -quantity, wholesaler_id, expiry_date, gtin_code], (err) => {
                if (err) {
                    console.error("❌ SQL Error (Deduction):", err);
                    return res.status(500).json({ error: "Deduction entry failed" });
                }

                // Step 4: Retailer Inventory check karo
                const checkRetailer = "SELECT id FROM retailer_inventory WHERE drug_name = ? AND batch_no = ? AND retailer_name = ?";
                db.query(checkRetailer, [drug_name, batch_no, retailer_name], (err, stockResult) => {
                    
                    if (stockResult && stockResult.length > 0) {
                        // Agar stock pehle se hai, toh Quantity update karo
                        const updateRetailerStock = "UPDATE retailer_inventory SET quantity = quantity + ?, expiry_date = ?, gtin_code = ? WHERE id = ?";
                        db.query(updateRetailerStock, [quantity, expiry_date, gtin_code, stockResult[0].id], (e) => {
                            if (e) return res.status(500).json({ error: "Retailer Update Failed" });
                            res.status(200).json({ message: "Success" });
                        });
                    } else {
                        // Agar stock nahi hai, toh Naya row insert karo
                        const insertRetailerStock = `INSERT INTO retailer_inventory (drug_name, batch_no, quantity, retailer_name, expiry_date, gtin_code) VALUES (?, ?, ?, ?, ?, ?)`;
                        db.query(insertRetailerStock, [drug_name, batch_no, quantity, retailer_name, expiry_date, gtin_code], (e) => {
                            if (e) return res.status(500).json({ error: "Retailer Insert Failed" });
                            res.status(200).json({ message: "Success" });
                        });
                    }
                });
            });
        });
    });
});

app.get('/get-accepted-history/:retailerName', (req, res) => {

    const retailerName = req.params.retailerName;

    const query = `
        SELECT 
            id,
            retailer_name,
            wholesaler_name,
            wholesaler_gstin,
             wholesaler_license,
            drug_name,
            batch_no,
            quantity,
            expiry_date,
            gtin_code,
            status,
            sale_date,
             received_date
        FROM transactions
        WHERE retailer_name = ?
        AND status = 'Accepted'
        ORDER BY id DESC
    `;

    db.query(query, [retailerName], (err, results) => {

        if (err) {
            console.error("❌ Accepted History Error:", err);
            return res.status(500).json({
                message: "Database fetch failed"
            });
        }

        console.log("✅ Accepted History:", results);

        res.status(200).json(results);
    });
});

app.get('/get-retailer-stock/:retailerName', (req, res) => {
    const query = `SELECT drug_name, batch_no, SUM(quantity) as total_qty, MIN(expiry_date) as expiry_date, MIN(gtin_code) as gtin_code FROM retailer_inventory WHERE retailer_name = ? GROUP BY drug_name, batch_no`;
    db.query(query, [req.params.retailerName], (err, results) => {
        if (err) {
            console.error("❌ Stock Fetch Error:", err);
            return res.status(500).json(err);
        }
        res.status(200).json(results);
    });
});

// --- RETAILER OUTWARD: SELL DRUG TO PATIENT ---
app.post('/retailer-sell-drug', (req, res) => {
    console.log("Received Data:", req.body);
    const { retailer_name, customer_name, customer_phone, abha_id, drug_name, quantity, doctor_name, sale_date, batch_no } = req.body;

    const checkStockQuery = "SELECT id, quantity, expiry_date, gtin_code FROM retailer_inventory WHERE retailer_name = ? AND drug_name = ? AND batch_no = ? AND quantity >= ?";
    
    db.query(checkStockQuery, [retailer_name, drug_name, batch_no, quantity], (err, rows) => {
        if (err) return res.status(500).json({ error: "Database error during stock check" });
        if (rows.length === 0) {
            return res.status(400).json({ message: "Stock insufficient or batch not found in your inventory!" });
        }

        const { id: stockId, expiry_date, gtin_code } = rows[0];

        const insertSaleQuery = `INSERT INTO retailer_sales (retailer_name, customer_name, customer_phone,  abha_id, drug_name, quantity, doctor_name, sale_date, batch_no, expiry_date, gtin_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

        db.query(insertSaleQuery, [retailer_name, customer_name, customer_phone, abha_id, drug_name, quantity, doctor_name, sale_date, batch_no, expiry_date, gtin_code], (err) => {
            if (err) return res.status(500).json({ error: "Failed to record sale transaction" });

            const deductStockQuery = "UPDATE retailer_inventory SET quantity = quantity - ? WHERE id = ?";
            db.query(deductStockQuery, [quantity, stockId], (err) => {
                if (err) return res.status(500).json({ error: "Failed to deduct quantity from live stock" });
                res.status(200).json({ message: "Drug sold successfully and live stock updated!" });
            });
        });
    });
});

app.get('/get-retailer-sales-history/:retailerName', (req, res) => {
    const query = "SELECT * FROM retailer_sales WHERE retailer_name = ? ORDER BY id DESC";
    db.query(query, [req.params.retailerName], (err, results) => {
        if (err) return res.status(500).json(err);
        res.status(200).json(results);
    });
});

// --- INSPECTOR PORTAL ENDPOINTS ---
app.get('/get-all-registered-users', (req, res) => {
    const query = "SELECT full_name, role, drug_license_no FROM users WHERE role IN ('Wholesaler', 'Retailer') ORDER BY full_name ASC";
    db.query(query, (err, results) => {
        if (err) return res.status(500).json({ error: "Failed to fetch users", details: err });
        res.status(200).json(results);
    });
});

app.get('/get-wholesaler-stock/:email', (req, res) => {

    const email = req.params.email;

    const query = `
        SELECT
            drug_name,
            batch_no,
            SUM(quantity) as total_qty
        FROM inventory
        WHERE owner_email = ?
        GROUP BY drug_name,batch_no
    `;

    db.query(query,[email],(err,results)=>{
        if(err) return res.status(500).json(err);
        res.json(results);
    });
});

app.get('/get-retailer-stock/:name', (req, res) => {

    const name = req.params.name;

    const query = `
        SELECT
            drug_name,
            batch_no,
            SUM(quantity) as total_qty
        FROM retailer_inventory
        WHERE retailer_name = ?
        GROUP BY drug_name,batch_no
    `;

    db.query(query,[name],(err,results)=>{
        if(err) return res.status(500).json(err);
        res.json(results);
    });
});

app.post("/submit-inspector-visit", (req, res) => {

  const {
    inspector_name,
    target_user_name,
    target_license_no,
    target_role,
    audit_date,
    license_verified,
    stock_verified,
    prescription_checked,
    storage_checked,
    seizure_required,
    total_digital_stock,
    total_physical_stock,
    overall_status,
    drugs
  } = req.body;

  const visitSql = `
    INSERT INTO inspector_visits
    (
      inspector_name,
      target_user_name,
      target_license_no,
      target_role,
      audit_date,
      license_verified,
      stock_verified,
      prescription_checked,
      storage_checked,
      seizure_required,
      total_digital_stock,
      total_physical_stock,
      overall_status
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  db.query(
    visitSql,
    [
      inspector_name,
      target_user_name,
      target_license_no,
      target_role,
      audit_date,
      license_verified,
      stock_verified,
      prescription_checked,
      storage_checked,
      seizure_required,
      total_digital_stock,
      total_physical_stock,
      overall_status
    ],
    (err, result) => {

      if (err) {
        console.log(err);
        return res.status(500).send(err);
      }

      const visitId = result.insertId;

      if (!drugs || drugs.length === 0) {
        return res.json({
          success: true
        });
      }

      const drugSql = `
        INSERT INTO inspector_visit_drugs
        (
          visit_id,
          drug_name,
          batch_no,
          digital_stock,
          physical_stock,
          mismatch,
          status
        )
        VALUES ?
      `;

      const drugValues = drugs.map((drug) => [
        visitId,
        drug.drug_name,
        drug.batch_no,
        drug.digital_stock,
        drug.physical_stock,
        drug.mismatch,
        drug.status
      ]);

      db.query(
        drugSql,
        [drugValues],
        (err2) => {

          if (err2) {
            console.log(err2);
            return res.status(500).send(err2);
          }

          res.json({
            success: true,
            message: "Inspection submitted"
          });
        }
      );
    }
  );
});



// ======================================================
// GET HISTORY
// ======================================================

app.get('/get-audit-history/:role/:inspectorName', (req, res) => {

  const role = req.params.role;
  const inspectorName = req.params.inspectorName;

  const query = `
    SELECT * FROM inspector_visits
    WHERE target_role = ?
    AND inspector_name = ?
    ORDER BY id DESC
  `;

  db.query(query, [role, inspectorName], (err, visits) => {

    if (err) {
      return res.status(500).json(err);
    }

    if (visits.length === 0) {
      return res.status(200).json([]);
    }

    let completed = 0;

    visits.forEach((visit, index) => {

      db.query(
        "SELECT * FROM inspector_visit_drugs WHERE visit_id=?",
        [visit.id],
        (e, drugs) => {

          visits[index].drugs = drugs;

          completed++;

          if (completed === visits.length) {
            res.status(200).json(visits);
          }
        }
      );
    });
  });
});

app.get('/get-profile', (req, res) => {
    const email = req.query.email;
    const query = "SELECT full_name, email, role, address FROM users WHERE email = ?";
    db.query(query, [email], (err, results) => {
        if (err || results.length === 0) return res.status(404).json({ message: "Profile not found" });
        res.status(200).json(results[0]);
    });
});

app.post('/update-profile', (req, res) => {
    const { current_email, full_name, address } = req.body;
    const query = "UPDATE users SET full_name = ?, address = ? WHERE email = ?";
    db.query(query, [full_name, address, current_email], (err, result) => {
        if (err) return res.status(500).json({ message: "Failed to update profile in DB" });
        res.status(200).json({ message: "Profile updated successfully!" });
    });
});

// --- MANUFACTURERS ENDPOINTS ---
app.post('/add-manufacturer', (req, res) => {
    const { wholesaler_email, name, address, phone, email, website, license_no, gstin } = req.body;
    if (!wholesaler_email || !name || !address || !phone || !email || !license_no || !gstin) {
        return res.status(400).json({ message: "All mandatory fields are required!" });
    }
    const query = `INSERT INTO manufacturers (wholesaler_email, manufacturer_name, address, phone, email, website, drug_license_no, gstin) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;
    db.query(query, [wholesaler_email, name, address, phone, email, website, license_no, gstin], (err, result) => {
        if (err) {
            console.error("❌ Manufacturer Insert Error:", err.message);
            return res.status(500).json({ message: "Database Error while saving manufacturer." });
        }
        res.status(200).json({ message: "Manufacturer Registered Successfully!" });
    });
});

// --- DRUGS MASTER & DROPDOWN ---
app.get('/get-all-drugs', (req, res) => {
    const query = `SELECT  brand_id, gtin, generic_name, drug_name, drug_name AS brand_name, strength, packaging_type, added_by FROM drugs_master ORDER BY id DESC`;
    db.query(query, (err, results) => {
        if (err) return res.status(500).json({ message: "Failed to fetch master drug records." });
        res.status(200).json(results);
    });
});

app.get('/get-all-manufacturers', (req, res) => {
    const query = `SELECT manufacturer_name AS name, drug_license_no AS license_no FROM manufacturers ORDER BY id DESC`;
    db.query(query, (err, results) => {
        if (err) return res.status(500).json({ message: "Failed to fetch manufacturer data." });
        res.status(200).json(results);
    });
});

app.post('/add-drug-master', (req, res) => {
    const {  brand_id, gtin, generic_name, brand_name, strength, packaging_type, added_by } = req.body;
    const query = `INSERT INTO drugs_master ( brand_id, gtin, generic_name, drug_name, strength, packaging_type, added_by) VALUES (?, ?, ?, ?, ?, ?, ?)`;
    db.query(query, [ brand_id, gtin, generic_name, brand_name, strength, packaging_type, added_by], (err, result) => {
        if (err) return res.status(500).json({ message: "Database failure during drug configuration." });
        res.status(200).json({ message: "Drug Registered Successfully!" });
    });
});

app.put('/update-drug-master', (req, res) => {
    const { gtin, generic_name, brand_name, strength, packaging_type, added_by } = req.body;
    const query = `UPDATE drugs_master SET generic_name = ?, drug_name = ?, strength = ?, packaging_type = ? WHERE gtin = ? AND added_by = ?`;
    db.query(query, [generic_name, brand_name, strength, packaging_type, gtin, added_by], (err, result) => {
        if (err) return res.status(500).json({ message: "Database error during modification." });
        res.status(200).json({ message: "Drug Master Catalog Updated Successfully!" });
    });
});

app.get('/get-gtin-by-batch/:drug_name/:batch_no', (req, res) => {
    const query = "SELECT gtin_code FROM inventory WHERE drug_name = ? AND batch_no = ? AND gtin_code IS NOT NULL LIMIT 1";
    db.query(query, [req.params.drug_name, req.params.batch_no], (err, results) => {
        if (err || results.length === 0) return res.status(404).json({ gtin_code: '' });
        res.json(results[0]);
    });
});

// Add this route to your index.js
app.get('/api/admin/stats', (req, res) => {
    const query = `
        SELECT 
            (SELECT COUNT(*) FROM users) as total_users,
            (SELECT COUNT(*) FROM inspector_visits) as total_audits;
    `;
    db.query(query, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results[0]); // Returns {total_users: 4, total_audits: 7}
    });
});

app.get('/api/admin/users', (req, res) => {
    db.query("SELECT full_name, role, drug_license_no FROM users", (err, results) => {
        res.json(results);
    });
});

app.get('/api/admin/all-audits', (req, res) => {
    // Yahan 'id' select karna mandatory hai taaki AuditDetailScreen kaam kare
    const query = "SELECT id, target_user_name, audit_date, overall_status, target_role FROM inspector_visits ORDER BY audit_date DESC";
    db.query(query, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

// index.js mein ye route update karein
app.get('/api/admin/users-list', (req, res) => {
    // ID aur STATUS dono select karna zaruri hai
    const query = "SELECT id, full_name, role, drug_license_no, gstin, status FROM users WHERE role IN ('Wholesaler', 'Retailer')";
    db.query(query, (err, results) => {
        if (err) return res.status(500).json(err);
        
        // Agar status NULL hai toh default 'Active' bhejenge
        const formattedResults = results.map(user => ({
            ...user,
            id: user.id || 0, // Id null hone par 0 set karein
            status: user.status || 'Active'
        }));
        res.json(formattedResults);
    });
});

// index.js
app.get('/api/admin/users/:role', (req, res) => {
    const role = req.params.role; // 'Wholesaler' ya 'Retailer'
    db.query("SELECT * FROM users WHERE role = ?", [role], (err, results) => {
        res.json(results);
    });
});

// User status change karne ke liye (Block/Unblock)
app.post('/api/admin/toggle-user-status', (req, res) => {
    const { id, status } = req.body; // status 'Active' ya 'Blocked' hoga
    const query = "UPDATE users SET status = ? WHERE id = ?";
    
    db.query(query, [status, id], (err, result) => {
        if (err) return res.status(500).json({ error: "Failed to update status" });
        res.json({ message: "User status updated successfully!" });
    });
});

app.get('/api/admin/audit-details/:visitId', (req, res) => {
    const visitId = req.params.visitId;
    const query = "SELECT * FROM inspector_visit_drugs WHERE visit_id = ?";
    db.query(query, [visitId], (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

app.get('/api/admin/inspector-performance', (req, res) => {
    const query = `
        SELECT 
            inspector_name, 
            COUNT(id) as total_visits, 
            SUM(CASE WHEN overall_status = 'MATCHED' THEN 1 ELSE 0 END) as successful_audits,
            SUM(CASE WHEN overall_status = 'UNMATCHED' THEN 1 ELSE 0 END) as failed_audits
        FROM inspector_visits 
        GROUP BY inspector_name
        ORDER BY total_visits DESC
    `;
    db.query(query, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

app.get('/api/admin/compliance-scorecard', (req, res) => {
    const query = `
        SELECT 
            u.id as target_user_id, -- <--- Yeh asli ID fetch karega
            iv.target_user_name,
            iv.target_role,
            COUNT(iv.id) as total_audits,
            SUM(CASE WHEN iv.overall_status = 'MATCHED' THEN 1 ELSE 0 END) as successful_audits,
            ROUND((SUM(CASE WHEN iv.overall_status = 'MATCHED' THEN 1 ELSE 0 END) / COUNT(iv.id)) * 100, 2) as compliance_score
        FROM inspector_visits iv
        LEFT JOIN users u ON iv.target_user_name = u.full_name -- Users table se link kiya
        GROUP BY iv.target_user_name, iv.target_role, u.id
        ORDER BY compliance_score ASC
    `;
    
    db.query(query, (err, results) => {
        if (err) {
            console.error("SQL Error:", err);
            return res.status(500).json(err);
        }
        res.json(results);
    });
});

app.post('/api/admin/log-action', (req, res) => {
    const { admin_email, action, target_user } = req.body;
    db.query("INSERT INTO admin_logs (admin_email, action, target_user) VALUES (?, ?, ?)", 
    [admin_email, action, target_user], (err) => {
        if (err) return res.status(500).json(err);
        res.status(200).json({ message: "Logged" });
    });
});
app.get('/api/admin/get-logs', (req, res) => {
    // Sabse naye logs pehle dikhane ke liye ORDER BY timestamp DESC
    const query = "SELECT * FROM admin_logs ORDER BY timestamp DESC";
    db.query(query, (err, results) => {
        if (err) return res.status(500).json(err);
        res.status(200).json(results);
    });
});

app.get('/api/admin/high-risk-count', (req, res) => {
    const query = `
        SELECT COUNT(*) as risk_count FROM (
            SELECT 
                target_user_name,
                ROUND((SUM(CASE WHEN overall_status = 'MATCHED' THEN 1 ELSE 0 END) / COUNT(iv.id)) * 100, 2) as compliance_score
            FROM inspector_visits iv
            GROUP BY target_user_name
            HAVING compliance_score <= 60
        ) as risk_users
    `;
    db.query(query, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results[0]);
    });
});

app.get('/api/admin/high-risk-list', (req, res) => {
    const query = `
        SELECT 
            target_user_name,
            ROUND((SUM(CASE WHEN overall_status = 'MATCHED' THEN 1 ELSE 0 END) / COUNT(id)) * 100, 2) as compliance_score
        FROM inspector_visits
        GROUP BY target_user_name
        HAVING compliance_score <= 60
    `;
    db.query(query, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

app.get('/api/admin/global-inventory', (req, res) => {
    const query = `
        SELECT drug_name, SUM(quantity) as total_quantity 
        FROM inventory 
        GROUP BY drug_name
    `;
    db.query(query, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});
app.get('/api/admin/user-inventory/:user_id', (req, res) => {

    const userId = req.params.user_id;

    db.query(
        "SELECT full_name, role FROM users WHERE id = ?",
        [userId],
        (err, userResult) => {

            if (err) {
                return res.status(500).json(err);
            }

            if (userResult.length === 0) {
                return res.json([]);
            }

            const user = userResult[0];

            if (user.role === 'Wholesaler') {

                const query = `
                    SELECT
                        drug_name,
                        batch_no,
                        SUM(quantity) AS quantity
                    FROM inventory
                    WHERE owner_id = ?
                    GROUP BY drug_name, batch_no
                    HAVING SUM(quantity) > 0
                `;

                db.query(query, [userId], (err, results) => {

                    if (err) {
                        return res.status(500).json(err);
                    }

                    res.json(results);
                });

            } else {

                const query = `
                    SELECT
                        drug_name,
                        batch_no,
                        SUM(quantity) AS quantity
                    FROM retailer_inventory
                    WHERE retailer_name = ?
                    GROUP BY drug_name, batch_no
                    HAVING SUM(quantity) > 0
                `;

                db.query(
                    query,
                    [user.full_name],
                    (err, results) => {

                        if (err) {
                            return res.status(500).json(err);
                        }

                        res.json(results);
                    }
                );
            }
        }
    );
});

app.get('/api/admin/drug-batches/:drug_name', (req, res) => {
    const drugName = req.params.drug_name;
    const query = `
        SELECT batch_no, expiry_date, SUM(quantity) as total_qty 
        FROM inventory 
        WHERE drug_name = ? 
        GROUP BY batch_no, expiry_date
    `;
    db.query(query, [drugName], (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

app.get('/inspector/drug-stock-summary', (req, res) => {

    const query = `
    SELECT
        drug_name,
        batch_no,
        SUM(quantity) AS total_qty
    FROM inventory
    GROUP BY drug_name,batch_no

    UNION ALL

    SELECT
        drug_name,
        batch_no,
        SUM(quantity) AS total_qty
    FROM retailer_inventory
    GROUP BY drug_name,batch_no
    `;

    db.query(query,(err,result)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.json(result);
    });
});

app.get('/inspector/drug-wholesalers/:drug/:batch', (req,res)=>{

    const {drug,batch} = req.params;

    const query = `
    SELECT
        u.full_name,
        u.drug_license_no,
        GREATEST(SUM(i.quantity),0) as quantity
    FROM inventory i
    JOIN users u
    ON i.owner_id=u.id
    WHERE i.drug_name=?
    AND i.batch_no=?
    AND u.role='Wholesaler'
    GROUP BY u.id
    `;

    db.query(query,[drug,batch],(err,result)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.json(result);
    });
});

app.get('/inspector/drug-retailers/:drug/:batch', (req,res)=>{

    const {drug,batch} = req.params;

    const query = `
    SELECT
        u.full_name,
        u.drug_license_no,
        ri.quantity
    FROM retailer_inventory ri
    JOIN users u
    ON ri.retailer_name=u.full_name
    WHERE ri.drug_name=?
    AND ri.batch_no=?
    `;

    db.query(query,[drug,batch],(err,result)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.json(result);
    });
});
app.get('/inspector/users-stock-list',(req,res)=>{

    const query = `
    SELECT
        full_name,
        drug_license_no,
        shop_name,
        role
    FROM users
    WHERE role IN ('Wholesaler','Retailer')
    ORDER BY full_name
    `;

    db.query(query,(err,result)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.json(result);
    });
});
app.get('/inspector/user-stock/:name/:role',(req,res)=>{

    const {name,role}=req.params;

    let query="";
    let params=[];

    if(role==="Wholesaler"){

        query = `
SELECT
    drug_name,
    batch_no,
    SUM(quantity) as qty
FROM inventory
WHERE owner_id = (
    SELECT id
    FROM users
    WHERE full_name = ?
    LIMIT 1
)
GROUP BY drug_name,batch_no
HAVING SUM(quantity) > 0
`;

params = [name];

    }else{

        query=`
        SELECT
            drug_name,
            batch_no,
            quantity as qty
        FROM retailer_inventory
        WHERE retailer_name=?
        `;

        params=[name];
    }

    db.query(query,params,(err,result)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.json(result);
    });
});

app.get('/inspector/drug-traceability', (req, res) => {

    const query = `
        SELECT DISTINCT
            drug_name,
            batch_no
        FROM
        (
            SELECT drug_name,batch_no
            FROM inventory

            UNION

            SELECT drug_name,batch_no
            FROM retailer_inventory
        ) x

        ORDER BY drug_name
    `;

    db.query(query,(err,results)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.json(results);
    });
});
app.get('/inspector/drug-holders/:drug/:batch', (req, res) => {

    const { drug, batch } = req.params;

    const wholesalerQuery = `
        SELECT
            u.full_name,
            u.drug_license_no,
            GREATEST(SUM(i.quantity),0) as quantity
        FROM inventory i
        JOIN users u
            ON i.owner_id = u.id
        WHERE i.drug_name = ?
        AND i.batch_no = ?
        GROUP BY u.id
    `;

    db.query(
        wholesalerQuery,
        [drug, batch],
        (err, wholesalers) => {

            if(err){
                return res.status(500).json(err);
            }

            const retailerQuery = `
                SELECT
                    u.full_name,
                    u.drug_license_no,
                    SUM(r.quantity) as quantity
                FROM retailer_inventory r
                JOIN users u
                    ON r.retailer_name = u.full_name
                WHERE r.drug_name = ?
                AND r.batch_no = ?
                GROUP BY u.id
            `;

            db.query(
                retailerQuery,
                [drug, batch],
                (err2, retailers) => {

                    if(err2){
                        return res.status(500).json(err2);
                    }

                    res.json({
                        wholesalers,
                        retailers
                    });
                }
            );
        }
    );
});
app.get('/inspector/users-stock/:role', (req, res) => {

    const role = req.params.role;

    const query = `
        SELECT
            id,
            full_name,
            drug_license_no,
            shop_name
        FROM users
        WHERE role = ?
        ORDER BY full_name
    `;

    db.query(query,[role],(err,results)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.json(results);
    });
});
app.get('/inspector/user-stock-details/:email/:role', (req,res)=>{

    const { email, role } = req.params;

    console.log("ROUTE HIT");
console.log("EMAIL =", email);
console.log("ROLE =", role);

    if(role === "Wholesaler"){

        const query = `
            SELECT
                drug_name,
                batch_no,
                SUM(quantity) as total_qty
            FROM inventory
            WHERE owner_email = ?
            GROUP BY drug_name,batch_no
            HAVING SUM(quantity) > 0
        `;

        db.query(query,[email],(err,results)=>{

            if(err){
                return res.status(500).json(err);
            }

            res.json(results);
        });

    }else{

        const getRetailer = `
            SELECT full_name
            FROM users
            WHERE email = ?
        `;

        db.query(getRetailer,[email],(e,user)=>{

            if(e){
                return res.status(500).json(e);
            }

            if(user.length === 0){
                return res.json([]);
            }

            const retailerName = user[0].full_name;

            const query = `
                SELECT
                    drug_name,
                    batch_no,
                    SUM(quantity) as total_qty
                FROM retailer_inventory
                WHERE retailer_name = ?
                GROUP BY drug_name,batch_no
                HAVING SUM(quantity) > 0
            `;

            db.query(query,[retailerName],(err,results)=>{

                if(err){
                    return res.status(500).json(err);
                }

                res.json(results);
            });
        });
    }
});
app.get('/inspector/user-stock/:role', (req, res) => {

    const role = req.params.role;

    const query = `
        SELECT
            id,
            full_name,
            email,
            drug_license_no,
            shop_name,
            role
        FROM users
        WHERE role = ?
        ORDER BY full_name
    `;

    db.query(query, [role], (err, results) => {

        if (err) {
            return res.status(500).json(err);
        }

        res.json(results);
    });
});

app.get('/api/admin/inspector-visits/:inspectorName', (req, res) => {

    const inspectorName = req.params.inspectorName;

    const query = `
        SELECT
            target_user_name,
            target_license_no,
            target_role,
            audit_date,
            overall_status
        FROM inspector_visits
        WHERE inspector_name = ?
        ORDER BY audit_date DESC
    `;

    db.query(query,[inspectorName],(err,results)=>{

        if(err){
            return res.status(500).json(err);
        }

        res.json(results);
    });
});
app.get('/api/admin/audit-full-details/:visitId', (req, res) => {
    const visitId = req.params.visitId;
    
    // Visit header aur drugs dono ek saath le aayein
    const query = `
        SELECT v.*, d.drug_name, d.batch_no, d.digital_stock, d.physical_stock, d.mismatch, d.status 
        FROM inspector_visits v
        LEFT JOIN inspector_visit_drugs d ON v.id = d.visit_id
        WHERE v.id = ?
    `;
    
    db.query(query, [visitId], (err, results) => {
        if (err) return res.status(500).json(err);
        if (results.length === 0) return res.status(404).json({ message: "No data found" });
        
        // Data structure ko format karein
        const response = {
            header: {
                inspector_name: results[0].inspector_name,
                target_user_name: results[0].target_user_name,
                target_license_no: results[0].target_license_no,
                audit_date: results[0].audit_date,
                total_digital: results[0].total_digital_stock,
                total_physical: results[0].total_physical_stock,
                // Status flags
                license_verified: results[0].license_verified,
                stock_verified: results[0].stock_verified,
                prescription_checked: results[0].prescription_checked,
                storage_checked: results[0].storage_checked,
                seizure_required: results[0].seizure_required
            },
            drugs: results.map(r => ({
                drug_name: r.drug_name,
                batch_no: r.batch_no,
                digital_stock: r.digital_stock,
                physical_stock: r.physical_stock,
                mismatch: r.mismatch,
                status: r.status
            }))
        };
        res.json(response);
    });
});

app.post('/verify-user', (req, res) => {

    const { email, phone } = req.body;

    db.query(
        "SELECT * FROM users WHERE email=? AND phone_no=?",
        [email, phone],
        (err, results) => {

            if (err) {
                return res.status(500).json({
                    message: "Server Error"
                });
            }

            if (results.length === 0) {
                return res.status(404).json({
                    message: "Invalid Email or Mobile Number"
                });
            }

            res.status(200).json({
                message: "User Verified"
            });
        }
    );
});

app.post('/change-forgot-password', async (req, res) => {

    const {
        email,
        phone,
        newPassword,
        confirmPassword
    } = req.body;

    if (newPassword !== confirmPassword) {
        return res.status(400).json({
            message: "Passwords do not match"
        });
    }

    const hashedPassword =
        await bcrypt.hash(newPassword, 10);

    db.query(
        `UPDATE users
         SET password=?
         WHERE email=? AND phone_no=?`,
        [hashedPassword, email, phone],
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    message: "Update Failed"
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    message: "User not found"
                });
            }

            res.status(200).json({
                message: "Password Updated Successfully"
            });
        }
    );
});

app.post('/update-user-profile', (req, res) => {

    const {
        userId,
        full_name,
        email,
        phone_no,
        drug_license_no
    } = req.body;

    const query = `
        UPDATE users
        SET
            full_name=?,
            email=?,
            phone_no=?,
            drug_license_no=?
        WHERE id=?
    `;

    db.query(
        query,
        [
            full_name,
            email,
            phone_no,
            drug_license_no,
            userId
        ],
        (err, result) => {

            if (err) {
                console.log(err);
                return res.status(500).json({
                    message: "Profile update failed"
                });
            }

            res.status(200).json({
                message: "Profile updated successfully"
            });
        }
    );
});
app.listen(5000, () => console.log("Server running on port 5000"));