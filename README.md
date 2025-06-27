<h1>Rocky Linux 9 Hardening Using the CIS Benchmark</h1>

![Static Badge](https://img.shields.io/badge/Author-Jared%20Carvente-blue)
![Static Badge](https://img.shields.io/badge/Release-December%202024-green)
![Static Badge](https://img.shields.io/badge/OS-Rocky%20Linux%209-red)
![Static Badge](https://img.shields.io/badge/Security%20Profile-Level%202-orange)


<h2>Introduction</h2>
<p>This project is aimed at automating the hardening process for Rocky Linux 9 workstations and servers.</p>

<h2>Key points</h2>
<li>This script has been designed to comply with the <strong>Level 2 Security Profile</strong></li>
<li>Make sure you are logged in as the root user, to do so, execute the following command:</li>
<pre><code> sudo su</code></pre>
<li>Head over to the directory where the scripts are.</li>
<li>Give the execution permission to both scripts</li>
<pre><code> 
chmod u+x ./cis_rocky_server_l2.sh
chmod u+x ./cis_rocky_workstation_l2.sh
</code></pre>
<li>Execute the correct script for your needs</li>
<pre><code> 
./cis_rocky_server_l2.sh
</code></pre>
<p>or</p>
<pre><code> 
./cis_rocky_workstation_l2.s
</code></pre>
