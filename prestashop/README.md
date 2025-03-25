# Post‑Installation Instructions for PrestaShop

---

## 0. Converting DOS (Windows) to Unix Line Endings

If you encounter an error like:

```bash
sudo: unable to execute ./install.sh: No such file or directory
```

this likely means the script has Windows-style **CRLF** line endings. To fix this:

1. **Install dos2unix:**
   ```bash
   sudo apt-get update
   sudo apt-get install dos2unix
   ```
2. **Convert the script:**
   ```bash
   dos2unix install.sh
   ```
3. **Make it executable (if necessary):**
   ```bash
   chmod +x install.sh
   ```
4. **Run the script again:**
   ```bash
   sudo ./install.sh
   ```

Once the script runs successfully, proceed with the steps below.

---

## 1. Launching the Installation Wizard

1. **Open your browser** and navigate to the **public IP address** or **domain name** of your server.  
   *Example:* `http://YOUR_SERVER_IP/prestashop`
2. The **PrestaShop Installation Assistant** should appear.

> **Note:** If the URL automatically includes "https://", remove it and use `http://YOUR_SERVER_IP/prestashop` since TLS/SSL is not yet configured.

---

## 2. License Agreements & System Compatibility

1. **Select your preferred language** and click **Next**.
2. **Accept the License Agreements** by checking the required box(es) and then click **Next**.
3. The installer will check your system’s compatibility with PrestaShop. If everything is compatible, click **Next**.

---

## 3. Configuring Shop Details & Admin Account

1. Enter the details for your **store** (e.g., shop name, country, time zone).
2. Provide your **admin account information**:
   - **First Name** and **Last Name**
   - **Admin Email Address**
   - **Secure Admin Password**
3. Click **Next** to continue.

---

## 4. Database Setup

1. Enter the database details you created in the script:
   - **Database Server Address:** Typically `127.0.0.1` or `localhost`
   - **Database Name:** `prestashop`
   - **Database User:** `ps_user`
   - **Database Password:** Replace `PASSWORD` with your actual password from the script (we keep the password as "PASSWORD" in the default installation script). 
2. Click **Test your database connection now!** to ensure PrestaShop can connect.
3. If the message “Database is connected” appears, click **Next**.

---

## 5. Finalizing the Installation

1. PrestaShop will now install the required database tables and files.
2. Once complete, you’ll see a confirmation screen with links to both the **Front Office** (storefront) and **Back Office** (admin panel).

---

## 6. Accessing Your Store

- **Front Office (Storefront):**  
  Visit `http://YOUR_SERVER_IP/` (or your domain) to view your live store, which will display a sample theme and products.

- **Back Office (Admin Panel):**  
  Click the link provided at the end of the installation process to access the admin login page. Sign in using the admin email and password you set up.

> **Security Reminder:** For security reasons, PrestaShop may ask you to rename or delete the `/install` folder after installation. Follow the on‑screen instructions, then execute:
> ```bash
> sudo rm -rf /var/www/html/prestashop/install
> ```

---

## 7. Next Steps

- **Secure Your Store:**  
  - Consider enabling HTTPS/SSL.
  - Regularly update your server packages.
  - Use strong, unique passwords for all admin accounts.

- **Customize Your Store:**  
  - Install additional themes or modules.
  - Configure payment and shipping options.
  - Set up taxes and localization settings.

- **Backups & Maintenance:**  
  - Schedule regular backups for your database and files.
  - Keep PrestaShop and its modules updated to the latest version.

---

For more detailed guidance on managing and customizing your setup, refer to [PrestaShop’s official documentation](https://docs.prestashop.com/).
