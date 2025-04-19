# AwesomeEHR 🏥

<div align="center">
  <img src="docs/images/project_background.png" alt="AwesomeEHR Project Background" width="50%" height="250px">
</div>

> *Note: This project was initiated during the author's research assistant internship at the **National Institute of Health Data Science (NIHDS) at Peking University**. It aims to foster collaboration and knowledge sharing within the Medical AI community, promoting advancements in healthcare data science and artificial intelligence applications in medicine.* 

## Overview

AwesomeEHR is a comprehensive PostgreSQL-based framework designed for extracting and analyzing Electronic Health Records (EHR) data, with a specific focus on common ICU critical conditions: **Acute Kidney Injury (AKI)**, **Sepsis-Associated AKI (SA-AKI)**, **Sepsis** and **Trauma**.

We provide standardized PostgreSQL queries and functions to extract, transform, and analyze complex medical data across multiple clinical domains. By offering ready-to-use code templates, it significantly reduces the data processing burden for researchers, allowing them to focus more on clinical insights and research outcomes rather than data wrangling tasks.

## Project Structure 📁
```
.
├── Timeseries/              # Time-series data analysis queries 📈
├── Concepts/               # Clinical concept definitions 📚
├── Medication/            # Medication-related queries 💊
├── Treatments/            # Treatment protocol queries 🏥
├── Demographics/          # Patient demographic information 👥
├── function.sql          # Core utility functions for data processing ⚙️
├── main.sql             # Main execution script coordinating all analyses 🚀
└── run.sql              # Runtime configuration and environment setup ⚡
```

## Features ✨
- **Comprehensive Clinical Analysis** 🔍: Supports analysis of various clinical conditions including:
  - Acidosis
  - Cholesterol disorders
  - CNS dysfunction
  - Coagulation disorders
  - Hepatic dysfunction
  - Metabolic disorders
  - And many more

- **Modular Architecture** 🏗️: Well-organized directory structure enabling:
  - Easy maintenance
  - Scalable development
  - Flexible integration

- **Standardized Query Framework** 📊: Consistent SQL query patterns for:
  - Time-series data analysis
  - Patient cohort identification
  - Clinical outcome assessment

## Prerequisites 📋
- PostgreSQL database system
- Access to EHR data in compatible format
- Appropriate database permissions

## Usage 💻
1. Configure database connection parameters in `run.sql`
2. Execute the main script:
   ```sql
   \i main.sql
   ```
3. Access specific clinical modules as needed through individual SQL files

## Technical Details 🔧
The framework implements a sophisticated query system that:
- Processes temporal clinical data
- Handles missing values and data inconsistencies
- Supports complex clinical concept definitions
- Enables longitudinal patient analysis

## Data Structure 📊
The system is designed to work with:
- Time-series clinical measurements
- Discrete clinical events
- Patient demographic information
- Medication administration records
- Treatment protocols

## Best Practices 📝
- All queries follow standardized naming conventions
- Comprehensive error handling
- Optimized for performance with large datasets
- Modular design for easy maintenance

## Contributing 🤝
Contributions are welcome. Please ensure:
1. Consistent SQL formatting
2. Proper documentation of new features
3. Testing with sample datasets
4. Adherence to existing naming conventions

## License 📄
This project is licensed under the Academic Research License. This license allows:
- Academic and research use
- Modification and distribution for research purposes
- Commercial use with prior written permission
- Citation of the original work in any derived research

The software is provided "as is" without warranty of any kind. Users are responsible for ensuring compliance with local regulations and institutional review board requirements when using this software with patient data.

## Contact 📧
For inquiries and contributions, please contact:
- Email: haoweixu0126@163.com

## Acknowledgments 🙏
This project is inspired by and builds upon the excellent work of the MIT Laboratory for Computational Physiology (MIT-LCP) team. We would like to acknowledge and thank the following repositories for their valuable contributions to the medical informatics community:

- [eICU Collaborative Research Database Code Repository](https://github.com/MIT-LCP/eicu-code)
- [MIMIC-IV Code Repository](https://github.com/MIT-LCP/mimic-iv/tree/master)

Their pioneering work in creating standardized SQL queries for EHR data analysis has been instrumental in advancing medical informatics research.
