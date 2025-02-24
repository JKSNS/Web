# Post‑Installation Instructions for OpenCart

Congratulations! You have successfully executed the OpenCart installation script. This README will guide you through the final steps to get your OpenCart store up and running.

---

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

Once the script runs successfully, follow the steps below to complete your OpenCart setup.

---

## 1. Access the Installation Wizard

Open your browser and navigate to the public IP address or domain name of your server, followed by `/opencart/upload/` (or simply `/opencart/` if that’s how you configured it).

For example:
```
http://YOUR_SERVER_IP/opencart/upload/
```
You should see the OpenCart Installation Wizard screen.

> **Note:** If you see that `https://` is automatically being added and you haven’t configured SSL/TLS, manually change it back to `http://` to continue with the installation.

---

## 2. License Agreement & Pre‑Installation Check

- **License**: Read and accept the OpenCart license terms.
- **Pre‑Installation Check**: The script will verify that your environment meets all the requirements (e.g., PHP extensions, file permissions). If all checks pass, click **Continue** to proceed.

---

## 3. Database Configuration

1. **Database Driver**: Select `MySQLi` (default).
2. **Hostname**: Typically `localhost` or `127.0.0.1`.
3. **Username**: The database username you created (e.g., `opencart_user`).
4. **Password**: The password you set in the script (e.g., `strong_password`).
5. **Database Name**: The database name you created (e.g., `opencartdb`).
6. **Port**: Usually `3306` (the default for MySQL/MariaDB).
7. **Prefix**: Leave as `oc_` or change if you prefer a different table prefix.

Click **Continue** to proceed.

---

## 4. Administrative Setup

- **Username**: The username you will use to log into your OpenCart admin panel (e.g., `admin`).
- **Password**: Choose a strong password.
- **E‑Mail**: Enter your admin email address.

Click **Continue** to finalize the installation. Once done, you’ll see a success message.

---

## 5. Remove or Rename the `install` Directory

For security reasons, OpenCart will prompt you to **delete or rename the `/install` folder** before you can use the site or admin panel. Follow the on‑screen prompt or run:

```bash
sudo rm -rf /var/www/html/opencart/upload/install
```
(or wherever your OpenCart directory is located).

---

## 6. Accessing Your Store

- **Store Front (Front Office)**:
  ```
  http://YOUR_SERVER_IP/opencart/upload/
  ```
  You’ll see the default OpenCart theme with some sample products (if included).

- **Admin Panel (Back Office)**:
  ```
  http://YOUR_SERVER_IP/opencart/upload/admin/
  ```
  Use the admin username and password you set in step 4 to log in. From here, you can manage products, categories, extensions, and more.

---

## 7. Next Steps

### 7.1 Secure Your Store
- **Enable HTTPS/SSL** if you have a valid SSL certificate.  
- **Keep your server packages up to date** to ensure security patches are applied.  
- **Use strong passwords** for all admin accounts and database users.

### 7.2 Customize Your Store
- **Themes & Extensions**: Explore the OpenCart Marketplace for additional themes and plugins.  
- **Payment & Shipping**: Configure payment gateways (e.g., PayPal, Stripe) and shipping methods.  
- **Localization**: Set up languages, currencies, and taxes according to your region.

### 7.3 Backups & Maintenance
- **Database Backups**: Regularly back up your `opencartdb` database.  
- **File Backups**: Keep a copy of your `/opencart/upload/` directory.  
- **Updates**: Stay current with OpenCart updates to get new features and security fixes.

---

## Need More Help?

Refer to the [OpenCart Documentation](https://docs.opencart.com/) for more detailed guidance on customizing and administering your store.

