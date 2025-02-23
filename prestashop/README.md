# Post‑Installation Instructions for PrestaShop

Congratulations! You have successfully executed the PrestaShop installation script. This README will guide you through the final steps to get your PrestaShop store up and running.

## 1. Access the Installation Wizard

1. **Open your browser** and navigate to the **public IP address** or **domain name** of your server.  
   - For example: `http://YOUR_SERVER_IP/`  
2. You should see the **PrestaShop Installation Assistant** screen.

## 2. License Agreements & System Compatibility

1. **Select your preferred language** and click **Next**.  
2. **Accept the License Agreements** by checking the box(es) and click **Next**.  
3. The installation script will check whether your environment is compatible with PrestaShop.  
   - If everything is compatible, click **Next** to proceed.

## 3. Shop Details & Admin Account

1. Enter the required details about your **store** (e.g., shop name, country, time zone).  
2. Provide your **account details**, such as:
   - **First name** and **last name**
   - **Admin email address**
   - **Admin password** (make sure it’s secure)
3. Click **Next** to continue.

## 4. Database Configuration

1. On the next screen, you’ll need to provide the database details you created in the script:
   - **Database server address**: Typically `127.0.0.1` or `localhost`
   - **Database name**: `prestashop`
   - **Database user**: `ps_user`
   - **Database password**: The password you set in the script (replace `PASSWORD` in the script with your actual password)
2. Click **Test your database connection now!** to verify that PrestaShop can connect.  
3. If you see “Database is connected,” click **Next** to finalize the installation.

## 5. Finalizing Installation

1. PrestaShop will install the required database tables and files.  
2. Once completed, you’ll see a confirmation screen with links to your **Front Office** (public store) and **Back Office** (admin panel).

## 6. Accessing Your Store

- **Store Front (Front Office):**  
  Visit `http://YOUR_SERVER_IP/` (or your domain) to see your live store. You’ll see a sample theme with products listed.  

- **Admin Panel (Back Office):**  
  Follow the link provided at the end of the installation to access the admin login page. Enter the **admin email** and **password** you created to manage your store settings, products, orders, and more.

> **Important:** For security reasons, PrestaShop may ask you to rename or delete the `/install` folder after installation. If so, follow the on‑screen instructions.

## 7. Next Steps

- **Secure Your Store:**  
  - Consider enabling HTTPS/SSL.
  - Keep your server packages up to date.
  - Use strong passwords for all admin accounts.

- **Customize Your Store:**  
  - Install new themes or modules.
  - Configure payment and shipping options.
  - Set up taxes and localization.

- **Backups & Maintenance:**  
  - Schedule regular backups of your database and files.
  - Keep PrestaShop and all modules updated to the latest version.

---

Refer to [PrestaShop’s official documentation](https://docs.prestashop.com/) for more in‑depth guidance on managing and customizing the setup. 