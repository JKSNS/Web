### 1. Access the WordPress Installation Wizard

- Open your browser and navigate to the IP address or domain name of your server.  
  For example:  
  ```
  http://YOUR_SERVER_IP/wordpress
  ```
  or simply
  ```
  http://localhost/
  ```
  if you are running WordPress locally.

> **Note:** If you receive a “secure connection” or “https” error and your URL has `https://` automatically prefixed, manually remove `https://` from the address bar. By default, this script does not configure SSL (HTTPS).  

---

### 2. Provide Site Information

1. **Site Title** – This will be the title displayed on your WordPress site.  
2. **Username** – This is **only** for logging in to your WordPress admin dashboard (not related to MySQL or system user credentials).  
3. **Password** – Choose a strong password. You will use it along with the username to access the WordPress admin panel.  
4. **Your Email** – The administrator’s email address. WordPress uses this for password resets, notifications, and other admin tasks.  
5. **Search Engine Visibility** – Optionally, you can discourage search engines from indexing your site if you’re still developing or do not want it public yet.  

Click **Install WordPress** when finished.

---

### 3. Database Details

During the automated script, we created the database and user for WordPress. These credentials were already written to your `wp-config.php`. You do **not** need to supply database details here—WordPress’ “famous 5-minute installation” wizard will skip directly to the site information screen. If you ever need to modify your database settings, they are stored in:

```
/srv/www/wordpress/wp-config.php
```

- **Database name:** `wordpress`  
- **Database user:** `wordpress`  
- **Database password:** `<your-password>` (the one you used in the script)

---

### 4. Completing the Installation

When you click **Install WordPress**, WordPress will set up the necessary database tables and configuration. If everything goes smoothly, you’ll see a success message:

```
WordPress has been installed. Thank you, and enjoy!
```

---

### 5. Accessing Your Site

- **Public Front End:**  
  Visit `http://YOUR_SERVER_IP/wordpress` (or the domain you have configured) to see your new WordPress site.

- **Admin Dashboard:**  
  Visit `http://YOUR_SERVER_IP/wordpress/wp-admin/` to log in with the username and password you just created. Once logged in, you can customize themes, install plugins, create posts, manage users, and more.

---

### 6. Next Steps

**1. Secure Your Site**  
- Consider enabling HTTPS/SSL (via Let’s Encrypt or another provider).  
- Keep your server packages updated (`sudo apt update && sudo apt upgrade -y` or equivalent).  
- Use strong passwords for all WordPress accounts.

**2. Customize Your Site**  
- **Themes:** Browse thousands of free and premium themes to change your site’s design.  
- **Plugins:** Add functionality (e.g., contact forms, SEO, security enhancements) with WordPress plugins.  
- **Menus & Widgets:** Organize your site’s navigation and sidebar/footer elements.

**3. Backups & Maintenance**  
- **Regular Backups:** Schedule backups of your database and `wp-content` directory.  
- **Updates:** Keep WordPress core, themes, and plugins up to date to ensure security patches are applied.

**4. Search Engine Optimization**  
- If you want your site indexed by search engines, make sure “Discourage search engines from indexing this site” is **not** checked in your WordPress **Settings** → **Reading**.  
- Consider installing popular SEO plugins (e.g., Yoast SEO, All in One SEO).

---

**That’s it!** You’ve successfully installed and configured WordPress. Now you can start customizing your new site, publishing content, and exploring the vast ecosystem of themes and plugins. Happy blogging (or business building)!
