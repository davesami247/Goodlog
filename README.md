# 🌟 Goodlog - Volunteer Impact Proof

> Log social good with verifiable records on the Stacks blockchain

## 📖 Overview

Goodlog is a decentralized smart contract that enables volunteers to log their community service hours and have them verified by authorized organizations. Built on Stacks using Clarity, it creates an immutable record of social impact that can be trusted and verified by anyone.

## ✨ Features

- 📝 **Log Volunteer Work**: Record hours, organization, and description of volunteer activities
- ✅ **Verification System**: Organizations can verify volunteer work through authorized verifiers
- 📊 **Impact Tracking**: Track total hours, verification rates, and impact scores
- 🏢 **Organization Management**: Organizations can register and manage their verifiers
- 🔍 **Transparent Records**: All volunteer logs are publicly viewable and immutable
- 📈 **Statistics Dashboard**: View comprehensive stats for volunteers and organizations

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Stacks and Clarity

### Installation

1. Clone or download the contract files
2. Place `Goodlog.clar` in your `contracts/` directory
3. Deploy using Clarinet

```bash
clarinet deploy
```

## 📋 Usage

### For Organizations

#### 1. Register Your Organization
```clarity
(contract-call? .Goodlog register-organization (list 'SP1ABC... 'SP2DEF...))
```

#### 2. Add Additional Verifiers
```clarity
(contract-call? .Goodlog add-verifier 'SP1ORG... 'SP1VERIFIER...)
```

#### 3. Verify Volunteer Work
```clarity
(contract-call? .Goodlog verify-volunteer-work u1)
```

### For Volunteers

#### 1. Log Your Volunteer Work
```clarity
(contract-call? .Goodlog log-volunteer-work 'SP1ORG... u5 "Helped at food bank distribution")
```

#### 2. Check Your Stats
```clarity
(contract-call? .Goodlog get-volunteer-stats 'SP1VOLUNTEER...)
```

#### 3. View Your Impact Score
```clarity
(contract-call? .Goodlog get-volunteer-impact-score 'SP1VOLUNTEER...)
```

### For Everyone

#### View Volunteer Logs
```clarity
(contract-call? .Goodlog get-volunteer-log u1)
```

#### Check Total Community Impact
```clarity
(contract-call? .Goodlog get-total-volunteer-hours)
```

## 🔧 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `register-organization` | Register as an organization with verifiers | `verifiers: (list 10 principal)` |
| `add-verifier` | Add a new verifier to organization | `organization: principal, verifier: principal` |
| `log-volunteer-work` | Log volunteer hours and activity | `organization: principal, hours: uint, description: string` |
| `verify-volunteer-work` | Verify a volunteer log entry | `log-id: uint` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-volunteer-log` | Get details of a specific log | Log data or none |
| `get-volunteer-stats` | Get volunteer's complete statistics | Stats object |
| `get-organization-stats` | Get organization's statistics | Stats object |
| `get-volunteer-impact-score` | Calculate volunteer's impact score (0-100) | uint |
| `get-volunteer-verification-rate` | Get verification rate percentage | uint |
| `get-total-volunteer-hours` | Get total verified hours across platform | uint |

## 📊 Data Structure

### Volunteer Log Entry
```clarity
{
  volunteer: principal,
  organization: principal,
  hours: uint,
  description: (string-ascii 500),
  timestamp: uint,
  block-height: uint,
  verified: bool,
  verifier: (optional principal)
}
```

### Volunteer Stats
```clarity
{
  total-hours: uint,
  total-logs: uint,
  verified-hours: uint,
  verified-logs: uint
}
```

## 🛡️ Security Features

- ✅ Volunteers cannot verify their own work
- ✅ Only authorized verifiers can verify logs
- ✅ Organizations manage their own verifier lists
- ✅ All data is immutable once recorded
- ✅ Input validation for hours and descriptions

## 🎯 Use Cases

- 🏫 **Schools**: Track student community service requirements
- 🏢 **Nonprofits**: Verify and acknowledge volunteer contributions  
- 🏛️ **Government**: Monitor community service programs
- 👥 **Individuals**: Build verifiable volunteer portfolios
- 🏆 **Awards**: Provide proof for volunteer recognition programs

## 🔮 Future Enhancements

- 🏅 NFT badges for milestone achievements
- 🌐 Cross-chain volunteer hour portability
- 📱 Mobile app integration
- 🤖 Automated verification through IoT devices
- 📧 Notification system for verifications

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.


