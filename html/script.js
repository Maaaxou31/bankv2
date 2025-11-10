let currentAccount = 'personal';
let accountData = null;
let cardsData = [];
let transactionsData = [];
let employeesData = [];

// Event Listeners
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'open':
            openBank(data.accountType || 'personal');
            break;
        case 'close':
            closeBank();
            break;
        case 'notification':
            showNotification(data.type, data.message);
            break;
        case 'updateBalance':
            updateBalance(data.accountType, data.balance);
            break;
        case 'refreshCards':
            loadCards();
            break;
        case 'refreshTransactions':
            loadTransactions();
            break;
    }
});

// Escape key to close
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeBank();
        closeAllModals();
    }
});

// Initialize
function init() {
    // Account switcher
    document.querySelectorAll('.account-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const accountType = this.dataset.account;
            switchAccount(accountType);
        });
    });

    // Navigation
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const tab = this.dataset.tab;
            switchTab(tab);
        });
    });

    // Close button
    document.getElementById('closeBtn').addEventListener('click', closeBank);

    // Quick actions
    document.getElementById('depositBtn').addEventListener('click', () => openModal('depositModal'));
    document.getElementById('withdrawBtn').addEventListener('click', () => openModal('withdrawModal'));
    document.getElementById('transferBtn').addEventListener('click', () => openModal('transferModal'));

    // Card actions
    document.getElementById('createCardBtn').addEventListener('click', () => openModal('createCardModal'));

    // Modal close buttons
    document.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', function() {
            closeModal(this.closest('.modal').id);
        });
    });

    // Deposit
    document.getElementById('confirmDeposit').addEventListener('click', confirmDeposit);

    // Withdraw
    document.getElementById('confirmWithdraw').addEventListener('click', confirmWithdraw);

    // Transfer
    document.getElementById('confirmTransfer').addEventListener('click', confirmTransfer);

    // Create card
    document.getElementById('confirmCreateCard').addEventListener('click', confirmCreateCard);

    // Pay all salaries
    document.getElementById('payAllSalariesBtn').addEventListener('click', payAllSalaries);
}

// Open bank
function openBank(accountType = 'personal') {
    currentAccount = accountType;
    document.getElementById('bankApp').style.display = 'flex';

    // Update account switcher
    document.querySelectorAll('.account-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.account === accountType) {
            btn.classList.add('active');
        }
    });

    // Show/hide salary tab for business accounts
    const salaryBtn = document.querySelector('.salary-btn');
    if (accountType === 'business') {
        salaryBtn.style.display = 'flex';
    } else {
        salaryBtn.style.display = 'none';
    }

    loadAccountData();
    loadCards();
    loadTransactions();

    if (accountType === 'business') {
        loadEmployees();
    }

    switchTab('home');
}

// Close bank
function closeBank() {
    document.getElementById('bankApp').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Switch account
function switchAccount(accountType) {
    currentAccount = accountType;

    document.querySelectorAll('.account-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.account === accountType) {
            btn.classList.add('active');
        }
    });

    const salaryBtn = document.querySelector('.salary-btn');
    if (accountType === 'business') {
        salaryBtn.style.display = 'flex';
    } else {
        salaryBtn.style.display = 'none';
        // Switch to home if we're on salary tab
        if (document.querySelector('.nav-btn.active').dataset.tab === 'salary') {
            switchTab('home');
        }
    }

    loadAccountData();
    loadCards();
    loadTransactions();

    if (accountType === 'business') {
        loadEmployees();
    }
}

// Switch tab
function switchTab(tabName) {
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.tab === tabName) {
            btn.classList.add('active');
        }
    });

    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });

    document.getElementById(tabName + '-tab').classList.add('active');
}

// Load account data
function loadAccountData() {
    fetch(`https://${GetParentResourceName()}/getAccountInfo`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            accountType: currentAccount
        })
    }).then(resp => resp.json()).then(data => {
        if (data) {
            accountData = data;
            updateUI();
        }
    });
}

// Update UI
function updateUI() {
    if (!accountData) return;

    const balance = parseFloat(accountData.balance).toFixed(2) + '€';
    const iban = accountData.iban;

    document.getElementById('balance').textContent = balance;
    document.getElementById('iban').textContent = iban;
    document.getElementById('accountBalance').textContent = balance;
    document.getElementById('accountIban').textContent = iban;

    if (currentAccount === 'personal') {
        document.getElementById('accountName').textContent = accountData.firstname + ' ' + accountData.lastname;
        document.getElementById('accountType').textContent = 'Personnel';
    } else {
        document.getElementById('accountName').textContent = accountData.society_label;
        document.getElementById('accountType').textContent = 'Entreprise';
    }

    const date = new Date(accountData.created_at);
    document.getElementById('accountDate').textContent = date.toLocaleDateString('fr-FR');
}

// Update balance
function updateBalance(accountType, balance) {
    if (accountType === currentAccount && accountData) {
        accountData.balance = balance;
        updateUI();
    }
}

// Load cards
function loadCards() {
    fetch(`https://${GetParentResourceName()}/getCards`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            accountType: currentAccount
        })
    }).then(resp => resp.json()).then(data => {
        cardsData = data || [];
        renderCards();
    });
}

// Render cards
function renderCards() {
    const cardsList = document.getElementById('cardsList');
    cardsList.innerHTML = '';

    if (cardsData.length === 0) {
        cardsList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-credit-card"></i>
                <p>Aucune carte bancaire</p>
            </div>
        `;
        return;
    }

    cardsData.forEach(card => {
        const isBlocked = card.is_blocked === 1;
        const statusClass = isBlocked ? 'blocked' : 'active';
        const statusText = isBlocked ? 'Bloquée' : 'Active';

        const cardElement = document.createElement('div');
        cardElement.className = 'card-item';
        cardElement.innerHTML = `
            <div class="card-header">
                <span class="card-type">${currentAccount === 'personal' ? 'Carte Personnelle' : 'Carte Entreprise'}</span>
                <span class="card-status ${statusClass}">${statusText}</span>
            </div>
            <div class="card-number">${formatCardNumber(card.card_number)}</div>
            <div class="card-details">
                <div class="card-detail">
                    <span class="card-detail-label">Expire</span>
                    <span class="card-detail-value">${card.expiry_date}</span>
                </div>
                <div class="card-detail">
                    <span class="card-detail-label">CVV</span>
                    <span class="card-detail-value">***</span>
                </div>
            </div>
            <div class="card-actions">
                <button class="btn ${isBlocked ? 'btn-success' : 'btn-danger'}" onclick="toggleCardBlock(${card.id})">
                    <i class="fas fa-${isBlocked ? 'unlock' : 'lock'}"></i>
                    ${isBlocked ? 'Débloquer' : 'Bloquer'}
                </button>
            </div>
        `;

        cardsList.appendChild(cardElement);
    });
}

// Format card number
function formatCardNumber(number) {
    return number.match(/.{1,4}/g).join(' ');
}

// Toggle card block
function toggleCardBlock(cardId) {
    fetch(`https://${GetParentResourceName()}/toggleCardBlock`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            cardId: cardId
        })
    });
}

// Load transactions
function loadTransactions() {
    fetch(`https://${GetParentResourceName()}/getTransactions`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            accountType: currentAccount
        })
    }).then(resp => resp.json()).then(data => {
        transactionsData = data || [];
        renderTransactions();
        renderRecentTransactions();
    });
}

// Render transactions
function renderTransactions() {
    const transactionsList = document.getElementById('transactionsList');
    transactionsList.innerHTML = '';

    if (transactionsData.length === 0) {
        transactionsList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-exchange-alt"></i>
                <p>Aucune transaction</p>
            </div>
        `;
        return;
    }

    transactionsData.forEach(transaction => {
        const isIncoming = transaction.to_iban === (accountData ? accountData.iban : '');
        const iconClass = isIncoming ? 'incoming' : 'outgoing';
        const icon = isIncoming ? 'fa-arrow-down' : 'fa-arrow-up';
        const amountClass = isIncoming ? 'incoming' : 'outgoing';
        const amount = (isIncoming ? '+' : '-') + parseFloat(transaction.amount).toFixed(2) + '€';

        const date = new Date(transaction.created_at);
        const dateStr = date.toLocaleDateString('fr-FR') + ' ' + date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });

        const transactionElement = document.createElement('div');
        transactionElement.className = 'transaction-item';
        transactionElement.innerHTML = `
            <div class="transaction-info">
                <div class="transaction-icon ${iconClass}">
                    <i class="fas ${icon}"></i>
                </div>
                <div class="transaction-details">
                    <div class="transaction-name">${isIncoming ? transaction.from_name : transaction.to_name}</div>
                    <div class="transaction-description">${transaction.description || getTransactionTypeLabel(transaction.type)}</div>
                </div>
            </div>
            <div class="transaction-right">
                <div class="transaction-amount ${amountClass}">${amount}</div>
                <div class="transaction-date">${dateStr}</div>
            </div>
        `;

        transactionsList.appendChild(transactionElement);
    });
}

// Render recent transactions
function renderRecentTransactions() {
    const recentList = document.getElementById('recentTransactionsList');
    recentList.innerHTML = '';

    const recent = transactionsData.slice(0, 5);

    if (recent.length === 0) {
        recentList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-exchange-alt"></i>
                <p>Aucune transaction récente</p>
            </div>
        `;
        return;
    }

    recent.forEach(transaction => {
        const isIncoming = transaction.to_iban === (accountData ? accountData.iban : '');
        const iconClass = isIncoming ? 'incoming' : 'outgoing';
        const icon = isIncoming ? 'fa-arrow-down' : 'fa-arrow-up';
        const amountClass = isIncoming ? 'incoming' : 'outgoing';
        const amount = (isIncoming ? '+' : '-') + parseFloat(transaction.amount).toFixed(2) + '€';

        const date = new Date(transaction.created_at);
        const dateStr = date.toLocaleDateString('fr-FR');

        const transactionElement = document.createElement('div');
        transactionElement.className = 'transaction-item';
        transactionElement.innerHTML = `
            <div class="transaction-info">
                <div class="transaction-icon ${iconClass}">
                    <i class="fas ${icon}"></i>
                </div>
                <div class="transaction-details">
                    <div class="transaction-name">${isIncoming ? transaction.from_name : transaction.to_name}</div>
                    <div class="transaction-description">${transaction.description || getTransactionTypeLabel(transaction.type)}</div>
                </div>
            </div>
            <div class="transaction-right">
                <div class="transaction-amount ${amountClass}">${amount}</div>
                <div class="transaction-date">${dateStr}</div>
            </div>
        `;

        recentList.appendChild(transactionElement);
    });
}

// Get transaction type label
function getTransactionTypeLabel(type) {
    const labels = {
        'transfer': 'Virement',
        'deposit': 'Dépôt',
        'withdraw': 'Retrait',
        'salary': 'Salaire',
        'fee': 'Frais'
    };
    return labels[type] || type;
}

// Load employees
function loadEmployees() {
    fetch(`https://${GetParentResourceName()}/getEmployees`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(data => {
        employeesData = data || [];
        renderEmployees();
    });
}

// Render employees
function renderEmployees() {
    const employeesList = document.getElementById('employeesList');
    employeesList.innerHTML = '';

    if (employeesData.length === 0) {
        employeesList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-users"></i>
                <p>Aucun employé en ligne</p>
            </div>
        `;
        return;
    }

    employeesData.forEach(employee => {
        const employeeElement = document.createElement('div');
        employeeElement.className = 'employee-item';
        employeeElement.innerHTML = `
            <div class="employee-info">
                <div class="employee-name">${employee.firstname} ${employee.lastname}</div>
                <div class="employee-details">
                    <span><i class="fas fa-id-card"></i> ${employee.grade_label}</span>
                    <span><i class="fas fa-university"></i> ${employee.iban}</span>
                </div>
            </div>
            <div>
                <span class="employee-salary">${employee.salary.toFixed(2)}€</span>
                <button class="btn btn-success" onclick='paySalary(${JSON.stringify(employee)})'>
                    <i class="fas fa-money-bill-wave"></i> Payer
                </button>
            </div>
        `;

        employeesList.appendChild(employeeElement);
    });
}

// Pay salary
function paySalary(employee) {
    fetch(`https://${GetParentResourceName()}/paySalary`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            employee: employee
        })
    });
}

// Pay all salaries
function payAllSalaries() {
    fetch(`https://${GetParentResourceName()}/payAllSalaries`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Confirm deposit
function confirmDeposit() {
    const amount = parseFloat(document.getElementById('depositAmount').value);

    if (isNaN(amount) || amount <= 0) {
        showNotification('error', 'Montant invalide');
        return;
    }

    fetch(`https://${GetParentResourceName()}/deposit`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            amount: amount,
            accountType: currentAccount
        })
    });

    closeModal('depositModal');
    document.getElementById('depositAmount').value = '';
}

// Confirm withdraw
function confirmWithdraw() {
    const amount = parseFloat(document.getElementById('withdrawAmount').value);
    const pin = document.getElementById('withdrawPin').value;

    if (isNaN(amount) || amount <= 0) {
        showNotification('error', 'Montant invalide');
        return;
    }

    if (pin.length !== 4) {
        showNotification('error', 'Code PIN invalide');
        return;
    }

    fetch(`https://${GetParentResourceName()}/withdraw`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            amount: amount,
            accountType: currentAccount,
            pin: pin
        })
    });

    closeModal('withdrawModal');
    document.getElementById('withdrawAmount').value = '';
    document.getElementById('withdrawPin').value = '';
}

// Confirm transfer
function confirmTransfer() {
    const iban = document.getElementById('transferIban').value;
    const amount = parseFloat(document.getElementById('transferAmount').value);
    const description = document.getElementById('transferDescription').value;

    if (!iban || iban.length < 14) {
        showNotification('error', 'IBAN invalide');
        return;
    }

    if (isNaN(amount) || amount <= 0) {
        showNotification('error', 'Montant invalide');
        return;
    }

    fetch(`https://${GetParentResourceName()}/transfer`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            targetIban: iban,
            amount: amount,
            accountType: currentAccount,
            description: description
        })
    });

    closeModal('transferModal');
    document.getElementById('transferIban').value = '';
    document.getElementById('transferAmount').value = '';
    document.getElementById('transferDescription').value = '';
}

// Confirm create card
function confirmCreateCard() {
    const pin = document.getElementById('newCardPin').value;
    const confirmPin = document.getElementById('confirmCardPin').value;

    if (pin.length !== 4 || confirmPin.length !== 4) {
        showNotification('error', 'Le code PIN doit contenir 4 chiffres');
        return;
    }

    if (pin !== confirmPin) {
        showNotification('error', 'Les codes PIN ne correspondent pas');
        return;
    }

    if (!accountData) {
        showNotification('error', 'Erreur: compte introuvable');
        return;
    }

    fetch(`https://${GetParentResourceName()}/createCard`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            accountType: currentAccount,
            pin: pin,
            iban: accountData.iban
        })
    });

    closeModal('createCardModal');
    document.getElementById('newCardPin').value = '';
    document.getElementById('confirmCardPin').value = '';
}

// Open modal
function openModal(modalId) {
    document.getElementById(modalId).classList.add('active');
}

// Close modal
function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

// Close all modals
function closeAllModals() {
    document.querySelectorAll('.modal').forEach(modal => {
        modal.classList.remove('active');
    });
}

// Show notification
function showNotification(type, message) {
    const notification = document.getElementById('notification');
    const notificationText = document.getElementById('notificationText');

    notificationText.textContent = message;

    if (type === 'error') {
        notification.classList.add('error');
    } else {
        notification.classList.remove('error');
    }

    notification.classList.add('show');

    setTimeout(() => {
        notification.classList.remove('show');
    }, 3000);
}

// Get resource name
function GetParentResourceName() {
    let num = 0;
    let a = '';
    try {
        a = window.location.href.split('/')[num];
        while (a === '' || a === 'https:' || a === 'http:') {
            num++;
            a = window.location.href.split('/')[num];
        }
        return a;
    } catch (err) {
        return 'bankv2';
    }
}

// Initialize on load
init();
