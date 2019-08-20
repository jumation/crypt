# Encrypt/decrypt Juniper type $9$ secrets in Junos

[Crypt.slax](https://github.com/jumation/crypt/blob/master/crypt.slax) is a Junos op script which encrypts plain text to Juniper type $9$ secrets and decrypts Juniper type $9$ secrets to plain text.

It supports two modes- interactive and non-interactive. In case the plain-text secret contains punctuation characters like `'`, `"`, `\` or plain-text secret should not be logged, then it is better to use interactive mode(`op crypt`).

## Overview

*Screencast of interactive mode:*

![crypt.slax in interactive mode](https://github.com/jumation/crypt/blob/master/screencapture_interactive.gif)

*Screencast of non-interactive mode:*

![crypt.slax in non-interactive mode](https://github.com/jumation/crypt/blob/master/screencapture_non-interactive.gif)


Tested using test-scripts in [t](https://github.com/jumation/crypt/tree/master/t) directory with [prove](https://perldoc.perl.org/prove.html) and [Juniper vMX](https://www.juniper.net/us/en/products-services/routing/mx-series/vmx/) running Junos 16.1R2.11:

![crypt.slax test results screenshot](https://github.com/jumation/crypt/blob/master/crypt_script_test_results.png)


## Installation

Copy(for example using [scp](https://en.wikipedia.org/wiki/Secure_copy)) the [crypt.slax](https://github.com/jumation/crypt/blob/master/crypt.slax) to `/var/db/scripts/op/` directory and enable the script file under `[edit system scripts op]`:

```
martin@vmx1> file list detail /var/db/scripts/op/crypt.slax                            
-rw-r--r--  1 root  wheel      14998 Aug 6  14:13 /var/db/scripts/op/crypt.slax
total files: 1

martin@vmx1>                                                                        

martin@vmx1> show configuration system scripts | display inheritance no-comments    
op {
    file crypt.slax {
        description "Encrypt/decrypt Juniper type $9$ secrets";
        /* verify the integrity of an op script before running the script */
        checksum sha-256 882e45ec81baaec74750233afe6706c53e211fb0f28e62dc026c5f95e174bb57;
    }
    no-allow-url;
}
synchronize;

martin@vmx1> 
```

In case of two routing engines, the script needs to be copied to the `/var/db/scripts/op/` directory on both routing engines.


## Acknowledgements

Based on [Crypt::Juniper](https://metacpan.org/pod/Crypt::Juniper) Perl module by Kevin Brintnall.

## License

[GNU General Public License v3.0](https://github.com/jumation/crypt/blob/master/LICENSE)
