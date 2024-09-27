# PS-SFV

`ps-sfv.ps1` is a PowerShell script designed to verify [Simple File Verification (SFV)](https://en.wikipedia.org/wiki/Simple_file_verification) checksums of files.

Mostly written by Github Copilot.

# Background

If you're like me, you have dozens of ancient [QuickSFV](https://www.quicksfv.org) checksum files laying around.
However that program has not seen any updates in the last 14 years so here's a Powershell script to check those CRC32's.

## Features

- Verify files against existing SFV checksums.
- Supports CRC32 checksum algorithm.

## Usage

### Verify SFV Checksums

To verify files against an existing SFV file:

```powershell
.\ps-sfv.ps1 "C:\path\to\file.sfv"
```

## Notes

Would be cool to use Powershell's own `Get-FileHash` but it doesn't support [CRC32](https://en.wikipedia.org/wiki/Computation_of_cyclic_redundancy_checks#CRC-32_algorithm) which was used by [QuickSFV](https://www.quicksfv.org)

## License

This project is licensed under the MIT License.
