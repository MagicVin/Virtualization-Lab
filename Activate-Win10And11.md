# Activate Windows 10&11
>  [Images](https://msguides.com/download-microsoft-office-windows-os)

## KMS Key
*   Home: TX9XD-98N7V-6WMQ6-BX7FG-H8Q99
*   Home N: 3KHY7-WNT83-DGQKR-F7HPR-844BM
*   Home Single Language: 7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH
*   Home Country Specific: PVMJN-6DFY6-9CCP6-7BKTT-D3WVR
*   Professional: W269N-WFGWX-YVC9B-4J6C9-T83GX or VK7JG-NPHTM-C97JM-9MPGT-3V66T
*   Professional N: MH37W-N47XK-V7XM9-C7227-GCQG9
*   Education: NW6C2-QMPVW-D7KKK-3GKT6-VCFB2
*   Education N: 2WH4N-8QGBV-H22JP-CT43Q-MDWWJ
*   Enterprise: NPPR9-FWDCX-D2C8J-H872K-2YT43
*   Enterprise N: DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4    

## KMS Servers
*   kms.msguides.com
*   kms8.msguides.com
*   kms.03k.org
*   kms.teevee.asia
*   s8.uk.to

## slmgr (Windows Software Licensing Management Tool)
```
Global options:
/ipk <Product Key>           -- install product key(replaces existing key)
/ato [Activation ID]         -- Activation Windows
/dli [Activation ID | All]   -- Display license information(default: current license)

Advanced Options:
/cpky                        -- Clear product key from the registry(prevents disclosure attacks)
/upk [Activation ID]         -- uninstall product key
/ckms [Activation ID]        -- Clear name of KMS computer used(set the port to the default)
```


## Manual activation
Open command prompt as administrator
   ```
   slmgr /upk                                # uninstall product key 
   slmgr /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX  # Install KMS client key
   slmgr /skms.s8.uk.to                      # Set KMS machine address
   slmgr /ato                                # Activate your Windows
   ```
