<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Restaurant Menu</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <style>
        /* Custom scrollbar */
        ::-webkit-scrollbar {
            width: 8px;
        }
        ::-webkit-scrollbar-track {
            background: #f1f1f1;
        }
        ::-webkit-scrollbar-thumb {
            background: #6b46c1;
            border-radius: 4px;
        }
        .dark ::-webkit-scrollbar-track {
            background: #2d3748;
        }
        .dark ::-webkit-scrollbar-thumb {
            background: #a78bfa;
        }
        /* Smooth transitions for modals */
        .modal {
            transition: opacity 0.3s ease, transform 0.3s ease;
        }
        .modal-hidden {
            opacity: 0;
            transform: translateY(20px);
        }
    </style>
</head>
<body class="bg-purple-50 dark:bg-gray-900 text-gray-900 dark:text-white font-sans">
    <!-- Main Container -->
    <div class="min-h-screen flex flex-col">
        <!-- Header -->
        <header class="bg-gradient-to-r from-purple-700 to-purple-500 text-white sticky top-0 z-20 shadow-lg">
            <div class="container mx-auto px-4 py-4 flex items-center justify-between">
                <div class="flex items-center space-x-2">
                    <a href="{{ url('/') }}" class="text-white hover:text-purple-200">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                        </svg>
                    </a>
                    <h1 class="text-xl font-semibold">{{ $restaurant->restaurant_name }} Menu</h1>
                </div>
                <div class="flex items-center space-x-4">
                    <button id="theme-toggle" class="text-white hover:text-purple-200">
                        <svg id="theme-icon" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
                        </svg>
                    </button>
                    <div class="relative">
                        <button id="cart-toggle" class="text-white hover:text-purple-200">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path>
                            </svg>
                            <span id="cart-count" class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center hidden">0</span>
                        </button>
                    </div>
                </div>
            </div>
        </header>

        <!-- Main Content -->
        <main class="container mx-auto px-4 py-6 flex-grow">
            <!-- Search Bar -->
            <div class="mb-6">
                <div class="relative">
                    <input type="text" id="search-input" placeholder="Search items..." class="w-full p-3 pl-10 rounded-lg bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 focus:outline-none focus:ring-2 focus:ring-purple-600 text-gray-900 dark:text-white">
                    <svg class="absolute left-3 top-3.5 w-5 h-5 text-purple-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                    </svg>
                    <button id="clear-search" class="absolute right-3 top-3.5 text-gray-500 dark:text-gray-400 hidden">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
            </div>

            <!-- Category Filters -->
            <div class="mb-6 overflow-x-auto whitespace-nowrap">
                <div class="flex space-x-3">
                    <button class="category-chip px-4 py-2 rounded-full bg-purple-100 dark:bg-gray-700 text-purple-700 dark:text-gray-300 font-semibold hover:bg-purple-600 hover:text-white transition" data-category-id="">All</button>
                    @foreach ($categories as $category)
                        <button class="category-chip px-4 py-2 rounded-full bg-purple-100 dark:bg-gray-700 text-purple-700 dark:text-gray-300 font-semibold hover:bg-purple-600 hover:text-white transition" data-category-id="{{ $category->id }}">{{ $category->name }}</button>
                    @endforeach
                </div>
            </div>

            <!-- Menu Items -->
            <div id="menu-items">
                @foreach ($categories as $category)
                    @if ($category->items->isNotEmpty())
                        <div class="category-section mb-8" data-category-id="{{ $category->id }}">
                            <h2 class="text-2xl font-bold text-purple-700 dark:text-white mb-4">{{ $category->name }}</h2>
                            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                                @foreach ($category->items as $item)
                                    <div class="item-card bg-white dark:bg-gray-800 rounded-lg shadow-md hover:shadow-lg transition p-4 cursor-pointer" data-item-id="{{ $item->id }}" data-item-name="{{ $item->name }}" data-item-price="{{ $item->price }}" data-item-description="{{ $item->description ?? '' }}" data-item-image="{{ $item->image ? url($item->image) : '' }}">
                                        <img src="{{ $item->image ? url($item->image) : 'https://via.placeholder.com/150' }}" alt="{{ $item->name }}" class="w-full h-40 object-cover rounded-lg mb-4">
                                        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ $item->name }}</h3>
                                        <p class="text-gray-600 dark:text-gray-400">${{ number_format($item->price, 2) }}</p>
                                        <div class="quantity-selector hidden mt-2 flex items-center space-x-2">
                                            <button class="decrement bg-purple-600 text-white rounded-full w-8 h-8 flex items-center justify-center">-</button>
                                            <span class="quantity text-gray-900 dark:text-white">0</span>
                                            <button class="increment bg-purple-600 text-white rounded-full w-8 h-8 flex items-center justify-center">+</button>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        </div>
                    @endif
                @endforeach
            </div>
        </main>

        <!-- Cart Summary (Sticky Bottom Bar) -->
        <div id="cart-summary" class="hidden bg-purple-700 text-white p-4 fixed bottom-0 left-0 right-0 shadow-lg">
            <div class="container mx-auto flex justify-between items-center">
                <div>
                    <span id="cart-total-items">0 Items</span> •
                    <span id="cart-total-price">$0.00</span>
                </div>
                <button id="view-cart" class="bg-white text-purple-700 px-4 py-2 rounded-lg font-semibold hover:bg-gray-100 transition">View Cart</button>
            </div>
        </div>

        <!-- Cart Modal -->
        <div id="cart-modal" class="modal fixed inset-0 bg-black bg-opacity-50 flex items-end sm:items-center justify-center hidden modal-hidden">
            <div class="bg-white dark:bg-gray-800 rounded-t-lg sm:rounded-lg w-full sm:w-96 max-h-[80vh] overflow-y-auto">
                <div class="p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Your Cart</h2>
                        <button id="close-cart" class="text-gray-600 dark:text-gray-400">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                            </svg>
                        </button>
                    </div>
                    <div id="cart-items" class="space-y-4"></div>
                    <div class="mt-4 pt-4 border-t border-gray-300 dark:border-gray-700">
                        <div class="flex justify-between text-lg font-semibold text-gray-900 dark:text-white">
                            <span>Total:</span>
                            <span id="cart-modal-total">$0.00</span>
                        </div>
                    </div>
                    <button id="proceed-to-table" class="w-full mt-4 bg-purple-600 text-white py-2 rounded-lg font-semibold hover:bg-purple-700 transition">Proceed to Table Number</button>
                </div>
            </div>
        </div>

        <!-- Product Detail Modal -->
        <div id="product-modal" class="modal fixed inset-0 bg-black bg-opacity-50 flex items-end sm:items-center justify-center hidden modal-hidden">
            <div class="bg-white dark:bg-gray-800 rounded-t-lg sm:rounded-lg w-full sm:w-96 max-h-[80vh] overflow-y-auto">
                <div class="p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white" id="product-name"></h2>
                        <button id="close-product" class="text-gray-600 dark:text-gray-400">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                            </svg>
                        </button>
                    </div>
                    <img id="product-image" src="" alt="" class="w-full h-48 object-cover rounded-lg mb-4">
                    <p id="product-description" class="text-gray-600 dark:text-gray-400 mb-4"></p>
                    <p id="product-price" class="text-lg font-semibold text-purple-600 dark:text-purple-400 mb-4"></p>
                    <div class="flex items-center space-x-2 mb-4">
                        <button id="product-decrement" class="bg-purple-600 text-white rounded-full w-8 h-8 flex items-center justify-center">-</button>
                        <span id="product-quantity" class="text-gray-900 dark:text-white">0</span>
                        <button id="product-increment" class="bg-purple-600 text-white rounded-full w-8 h-8 flex items-center justify-center">+</button>
                    </div>
                    <textarea id="product-note" placeholder="Special note (e.g., No chili...)" class="w-full p-3 rounded-lg bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-700 focus:outline-none focus:ring-2 focus:ring-purple-600 text-gray-900 dark:text-white"></textarea>
                    <button id="add-to-cart" class="w-full mt-4 bg-purple-600 text-white py-2 rounded-lg font-semibold hover:bg-purple-700 transition">Add to Cart</button>
                </div>
            </div>
        </div>

        <!-- Table Number Modal -->
        <div id="table-number-modal" class="modal fixed inset-0 bg-black bg-opacity-50 flex items-end sm:items-center justify-center hidden modal-hidden">
            <div class="bg-white dark:bg-gray-800 rounded-t-lg sm:rounded-lg w-full sm:w-96 p-6">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Enter Table Number</h2>
                    <button id="close-table-modal" class="text-gray-600 dark:text-gray-400">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <form id="table-number-form">
                    <div class="mb-4">
                        <label for="table-number" class="block text-gray-900 dark:text-white mb-2">Table Number</label>
                        <input type="number" id="table-number" class="w-full p-3 rounded-lg bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-700 focus:outline-none focus:ring-2 focus:ring-purple-600 text-gray-900 dark:text-white" required>
                        <p id="table-error" class="text-red-500 text-sm mt-2 hidden"></p>
                    </div>
                    <button type="submit" id="submit-table" class="w-full bg-purple-600 text-white py-2 rounded-lg font-semibold hover:bg-purple-700 transition flex items-center justify-center">
                        <span>Submit Order</span>
                        <svg id="submit-loading" class="w-5 h-5 ml-2 animate-spin hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 12a8 8 0 0116 0"></path>
                        </svg>
                    </button>
                </form>
            </div>
        </div>

        <!-- Success Modal -->
        <div id="success-modal" class="modal fixed inset-0 bg-black bg-opacity-50 flex items-end sm:items-center justify-center hidden modal-hidden">
            <div class="bg-white dark:bg-gray-800 rounded-t-lg sm:rounded-lg w-full sm:w-96 p-6">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Order Confirmed</h2>
                    <button id="close-success-modal" class="text-gray-600 dark:text-gray-400">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <p class="text-gray-600 dark:text-gray-400 mb-4">Your order has been placed successfully!</p>
                <p class="text-gray-600 dark:text-gray-400 mb-4">Table Number: <span id="success-table-number"></span></p>
                <div id="success-order-items" class="space-y-2"></div>
                <p class="text-lg font-semibold text-purple-600 dark:text-purple-400 mt-4">Total: <span id="success-total"></span></p>
                <a href="{{ route('web.menu-preview', ['id' => $restaurant->id]) }}" class="w-full mt-4 bg-purple-600 text-white py-2 rounded-lg font-semibold hover:bg-purple-700 transition block text-center">Back to Menu</a>
            </div>
        </div>
    </div>

    <script>
        // Initialize cart
        let cart = [];
        let selectedCategoryId = null;

        // Theme toggle
        const themeToggle = document.getElementById('theme-toggle');
        const themeIcon = document.getElementById('theme-icon');
        themeToggle.addEventListener('click', () => {
            document.body.classList.toggle('dark');
            localStorage.setItem('theme', document.body.classList.contains('dark') ? 'dark' : 'light');
            themeIcon.innerHTML = document.body.classList.contains('dark') ?
                `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"></path>` :
                `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>`;
        });
        if (localStorage.getItem('theme') === 'dark') {
            document.body.classList.add('dark');
            themeIcon.innerHTML = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"></path>`;
        }

        // Cart management
        function updateCart() {
            const cartCount = document.getElementById('cart-count');
            const cartSummary = document.getElementById('cart-summary');
            const cartItemsDiv = document.getElementById('cart-items');
            const cartTotalItems = document.getElementById('cart-total-items');
            const cartTotalPrice = document.getElementById('cart-total-price');
            const cartModalTotal = document.getElementById('cart-modal-total');

            const itemQuantities = cart.reduce((acc, item) => {
                acc[item.id] = (acc[item.id] || 0) + 1;
                return acc;
            }, {});
            const totalItems = cart.length;
            const totalPrice = cart.reduce((sum, item) => sum + item.price, 0);

            cartCount.textContent = totalItems;
            cartCount.classList.toggle('hidden', totalItems === 0);
            cartSummary.classList.toggle('hidden', totalItems === 0);

            cartTotalItems.textContent = `${totalItems} Item${totalItems !== 1 ? 's' : ''}`;
            cartTotalPrice.textContent = `$${totalPrice.toFixed(2)}`;
            cartModalTotal.textContent = `$${totalPrice.toFixed(2)}`;

            cartItemsDiv.innerHTML = '';
            Object.entries(itemQuantities).forEach(([itemId, quantity]) => {
                const item = cart.find(i => i.id == itemId);
                const div = document.createElement('div');
                div.className = 'flex items-center justify-between p-2 bg-gray-100 dark:bg-gray-700 rounded-lg';
                div.innerHTML = `
                    <div class="flex items-center space-x-2">
                        <img src="${item.image || 'https://via.placeholder.com/50'}" alt="${item.name}" class="w-12 h-12 object-cover rounded-lg">
                        <div>
                            <p class="font-semibold text-gray-900 dark:text-white">${item.name}</p>
                            <p class="text-gray-600 dark:text-gray-400">$${item.price.toFixed(2)} x ${quantity}</p>
                            ${item.note ? `<p class="text-sm text-gray-500 dark:text-gray-400">Note: ${item.note}</p>` : ''}
                        </div>
                    </div>
                    <div class="flex items-center space-x-2">
                        <button class="decrement bg-purple-600 text-white rounded-full w-6 h-6 flex items-center justify-center" data-item-id="${item.id}">-</button>
                        <span class="text-gray-900 dark:text-white">${quantity}</span>
                        <button class="increment bg-purple-600 text-white rounded-full w-6 h-6 flex items-center justify-center" data-item-id="${item.id}">+</button>
                    </div>
                `;
                cartItemsDiv.appendChild(div);
            });

            document.querySelectorAll('#cart-items .decrement').forEach(btn => {
                btn.addEventListener('click', () => {
                    const itemId = btn.dataset.itemId;
                    const index = cart.findIndex(item => item.id == itemId);
                    if (index !== -1) {
                        cart.splice(index, 1);
                        updateCart();
                    }
                });
            });

            document.querySelectorAll('#cart-items .increment').forEach(btn => {
                btn.addEventListener('click', () => {
                    const itemId = btn.dataset.itemId;
                    const item = cart.find(item => item.id == itemId);
                    cart.push({ ...item });
                    updateCart();
                });
            });

            document.querySelectorAll('.quantity-selector').forEach(selector => {
                const itemId = selector.closest('.item-card').dataset.itemId;
                const quantity = itemQuantities[itemId] || 0;
                selector.querySelector('.quantity').textContent = quantity;
                selector.classList.toggle('hidden', quantity === 0);
            });
        }

        // Item click to show product modal
        document.querySelectorAll('.item-card').forEach(card => {
            card.addEventListener('click', () => {
                const item = {
                    id: card.dataset.itemId,
                    name: card.dataset.itemName,
                    price: parseFloat(card.dataset.itemPrice),
                    description: card.dataset.itemDescription,
                    image: card.dataset.itemImage,
                    note: ''
                };
                document.getElementById('product-name').textContent = item.name;
                document.getElementById('product-price').textContent = `$${item.price.toFixed(2)}`;
                document.getElementById('product-description').textContent = item.description || 'No description available.';
                document.getElementById('product-image').src = item.image || 'https://via.placeholder.com/150';
                document.getElementById('product-note').value = '';
                const quantity = cart.filter(i => i.id == item.id).length;
                document.getElementById('product-quantity').textContent = quantity;

                const modal = document.getElementById('product-modal');
                modal.classList.remove('hidden', 'modal-hidden');

                document.getElementById('product-increment').onclick = () => {
                    cart.push({ ...item, note: document.getElementById('product-note').value });
                    updateCart();
                    document.getElementById('product-quantity').textContent = cart.filter(i => i.id == item.id).length;
                };
                document.getElementById('product-decrement').onclick = () => {
                    const index = cart.findIndex(i => i.id == item.id);
                    if (index !== -1) {
                        cart.splice(index, 1);
                        updateCart();
                        document.getElementById('product-quantity').textContent = cart.filter(i => i.id == item.id).length;
                    }
                };
                document.getElementById('add-to-cart').onclick = () => {
                    const note = document.getElementById('product-note').value;
                    cart.filter(i => i.id == item.id).forEach(i => i.note = note);
                    updateCart();
                    modal.classList.add('hidden');
                    setTimeout(() => modal.classList.add('modal-hidden'), 300);
                };
            });
        });

        // Search functionality
        document.getElementById('search-input').addEventListener('input', () => {
            const searchText = document.getElementById('search-input').value.toLowerCase();
            document.getElementById('clear-search').classList.toggle('hidden', !searchText);
            document.querySelectorAll('.item-card').forEach(card => {
                const name = card.dataset.itemName.toLowerCase();
                card.closest('.category-section').classList.toggle('hidden', !name.includes(searchText) && selectedCategoryId);
                card.classList.toggle('hidden', !name.includes(searchText));
            });
        });
        document.getElementById('clear-search').addEventListener('click', () => {
            document.getElementById('search-input').value = '';
            document.getElementById('clear-search').classList.add('hidden');
            document.querySelectorAll('.item-card, .category-section').forEach(el => el.classList.remove('hidden'));
        });

        // Category filter
        document.querySelectorAll('.category-chip').forEach(chip => {
            chip.addEventListener('click', () => {
                document.querySelectorAll('.category-chip').forEach(c => c.classList.remove('bg-purple-600', 'text-white'));
                chip.classList.add('bg-purple-600', 'text-white');
                selectedCategoryId = chip.dataset.categoryId || null;
                document.querySelectorAll('.category-section').forEach(section => {
                    section.classList.toggle('hidden', selectedCategoryId && section.dataset.categoryId !== selectedCategoryId);
                });
                document.getElementById('search-input').value = '';
                document.getElementById('clear-search').classList.add('hidden');
            });
        });

        // Modal controls
        document.getElementById('close-product').addEventListener('click', () => {
            const modal = document.getElementById('product-modal');
            modal.classList.add('hidden');
            setTimeout(() => modal.classList.add('modal-hidden'), 300);
        });
        document.getElementById('cart-toggle').addEventListener('click', () => {
            const modal = document.getElementById('cart-modal');
            modal.classList.remove('hidden', 'modal-hidden');
        });
        document.getElementById('view-cart').addEventListener('click', () => {
            const modal = document.getElementById('cart-modal');
            modal.classList.remove('hidden', 'modal-hidden');
        });
        document.getElementById('close-cart').addEventListener('click', () => {
            const modal = document.getElementById('cart-modal');
            modal.classList.add('hidden');
            setTimeout(() => modal.classList.add('modal-hidden'), 300);
        });
        document.getElementById('proceed-to-table').addEventListener('click', () => {
            document.getElementById('cart-modal').classList.add('hidden');
            setTimeout(() => document.getElementById('cart-modal').classList.add('modal-hidden'), 300);
            const modal = document.getElementById('table-number-modal');
            modal.classList.remove('hidden', 'modal-hidden');
        });
        document.getElementById('close-table-modal').addEventListener('click', () => {
            const modal = document.getElementById('table-number-modal');
            modal.classList.add('hidden');
            setTimeout(() => modal.classList.add('modal-hidden'), 300);
        });
        document.getElementById('close-success-modal').addEventListener('click', () => {
            const modal = document.getElementById('success-modal');
            modal.classList.add('hidden');
            setTimeout(() => modal.classList.add('modal-hidden'), 300);
        });

        // Table number submission
        document.getElementById('table-number-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const tableNumber = document.getElementById('table-number').value;
            const submitButton = document.getElementById('submit-table');
            const loadingIcon = document.getElementById('submit-loading');
            const errorDiv = document.getElementById('table-error');

            if (!tableNumber) {
                errorDiv.textContent = 'Please enter a table number';
                errorDiv.classList.remove('hidden');
                return;
            }

            submitButton.disabled = true;
            loadingIcon.classList.remove('hidden');
            errorDiv.classList.add('hidden');

            try {
                const items = cart.reduce((acc, item) => {
                    const existing = acc.find(i => i.item_id == item.id);
                    if (existing) {
                        existing.quantity++;
                        if (item.note) existing.special_note = item.note;
                    } else {
                        acc.push({
                            item_id: item.id,
                            quantity: 1,
                            special_note: item.note || null
                        });
                    }
                    return acc;
                }, []);

                const response = await axios.post('{{ route('web.submit-order', ['id' => $restaurant->id]) }}', {
                    table_number: parseInt(tableNumber),
                    items: items
                }, {
                    headers: {
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                    }
                });

                const successModal = document.getElementById('success-modal');
                document.getElementById('success-table-number').textContent = tableNumber;
                document.getElementById('success-total').textContent = `$${cart.reduce((sum, item) => sum + item.price, 0).toFixed(2)}`;
                const successItems = document.getElementById('success-order-items');
                successItems.innerHTML = '';
                Object.entries(items.reduce((acc, item) => {
                    acc[item.item_id] = { quantity: (acc[item.item_id]?.quantity || 0) + item.quantity, note: item.special_note };
                    return acc;
                }, {})).forEach(([itemId, data]) => {
                    const item = cart.find(i => i.id == itemId);
                    const div = document.createElement('div');
                    div.className = 'flex justify-between text-gray-600 dark:text-gray-400';
                    div.innerHTML = `
                        <span>${item.name} x${data.quantity}</span>
                        <span>$${item.price.toFixed(2)}</span>
                        ${data.note ? `<p class="text-sm">Note: ${data.note}</p>` : ''}
                    `;
                    successItems.appendChild(div);
                });

                document.getElementById('table-number-modal').classList.add('hidden');
                setTimeout(() => document.getElementById('table-number-modal').classList.add('modal-hidden'), 300);
                successModal.classList.remove('hidden', 'modal-hidden');
                cart = [];
                updateCart();
            } catch (error) {
                errorDiv.textContent = error.response?.data?.error || 'Failed to submit order';
                errorDiv.classList.remove('hidden');
            } finally {
                submitButton.disabled = false;
                loadingIcon.classList.add('hidden');
            }
        });
    </script>
</body>
</html>