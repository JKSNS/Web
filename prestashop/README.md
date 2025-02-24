# Post‑Installation Instructions for PrestaShop

Congratulations! You have successfully executed the PrestaShop installation script. This README will guide you through the final steps to get your PrestaShop store up and running.

## 0. DOS (Windows) to Unix Line Endings

If you encountered an error such as:

```
sudo: unable to execute ./install.sh: No such file or directory
```

even though the file is clearly there, it likely means the script was created or edited on Windows and has **CRLF** (Windows) line endings instead of **LF** (Unix) line endings. To fix this:

1. **Install `dos2unix`:**
   ```bash
   sudo apt-get update
   sudo apt-get install dos2unix
   ```
2. **Convert the script:**
   ```bash
   dos2unix install.sh
   ```
3. **Make it executable (if needed):**
   ```bash
   chmod +x install.sh
   ```
4. **Re-run the script**:
   ```bash
   sudo ./install.sh
   ```

Once the script runs successfully, follow the steps below to complete your Wordpress setup.

## 1. Access the Installation Wizard

1. **Open your browser** and navigate to the **public IP address** or **domain name** of your server.  
   - For example: `http://YOUR_SERVER_IP/prestashop`  
2. You should see the **PrestaShop Installation Assistant** screen.

**note:** If you don't see the prestashop site but there's been "https://" added to the beginning of your web query, you must remove that and directly navigate to `YOUR_SERVER_IP/prestashop` since TLS has not been configured. 

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
<br>
<br>
sudo rm -rf /var/www/html/prestashop/install

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
