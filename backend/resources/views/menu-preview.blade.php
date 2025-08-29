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
        @import url('https://fonts.googleapis.com/css2?family=Battambang:wght@100;300;400;700;900&family=Source+Sans+3:ital,wght@0,200..900;1,200..900&display=swap');
        body.km {
            font-family: 'Battambang', sans-serif;
        }
        body.en {
            font-family: 'Source Sans 3', sans-serif;
        }
        body.dark {
            background-color: #1f2937;
            color: #e5e7eb;
        }
        body.dark .bg-white {
            background-color: #374151;
        }
        body.dark .text-gray-900 {
            color: #e5e7eb;
        }
        body.dark .text-gray-600 {
            color: #d1d5db;
        }
        body.dark .bg-purple-50 {
            background-color: #1f2937;
        }
        body.dark .bg-gray-100 {
            background-color: #4b5563;
        }
        body.dark .border-gray-300 {
            border-color: #6b7280;
        }
        ::-webkit-scrollbar { width: 8px; }
        ::-webkit-scrollbar-track { background: #f1f1f1; }
        ::-webkit-scrollbar-track.dark { background: #374151; }
        ::-webkit-scrollbar-thumb { background: #6b46c1; border-radius: 4px; }
        .modal { transition: opacity 0.3s ease, transform 0.3s ease; }
        .modal-hidden { opacity: 0; transform: translateY(20px); }
        #language-toggle img {
            width: 24px;
            height: 24px;
            border-radius: 50%;
            object-fit: cover;
        }
        @keyframes checkmark {
            0% { transform: scale(0); opacity: 0; }
            50% { transform: scale(1.2); opacity: 1; }
            100% { transform: scale(1); opacity: 1; }
        }
        .checkmark {
            animation: checkmark 0.5s ease-in-out forwards;
        }
        .item-card {
            height: 100px;
            padding: 8px;
        }
        .item-card img {
            width: 50px;
            height: 50px;
            object-fit: cover;
        }
        .quantity-selector {
            display: flex;
            align-items: center;
            gap: 4px;
        }
        .quantity-selector button {
            width: 24px;
            height: 24px;
            background-color: #6b46c1;
            color: white;
            border-radius: 50%;
            border: none;
            cursor: pointer;
            font-size: 16px;
            font-weight: bold;
        }
        .quantity-selector span {
            font-size: 14px;
            min-width: 20px;
            text-align: center;
        }
        #basket-button {
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            width: 90%;
            max-width: 400px;
            padding: 12px;
            background-color: #6b46c1;
            color: white;
            border-radius: 8px;
            text-align: center;
            font-size: 16px;
            font-weight: bold;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            z-index: 30;
            transition: opacity 0.3s ease;
        }
        #basket-button.hidden {
            opacity: 0;
            pointer-events: none;
        }
        /* Table error styling (default until image is provided) */
        #table-error {
            background-color: #fee2e2;
            color: #dc2626;
            padding: 0.5rem;
            border-radius: 0.375rem;
            margin-top: 0.5rem;
            display: flex;
            align-items: center;
        }
        #table-error svg {
            width: 1.25rem;
            height: 1.25rem;
            margin-right: 0.5rem;
        }
    </style>
</head>
<body class="bg-purple-50 text-gray-900 en">
    <div class="min-h-screen flex flex-col">
        <header class="bg-gradient-to-r from-purple-700 to-purple-500 text-white sticky top-0 z-20 shadow-lg">
            <div class="container mx-auto px-4 py-4 flex items-center justify-between">
                <div class="flex items-center space-x-4">
                    <img src="{{ $restaurant->profile ? url('storage/' . $restaurant->profile) : 'https://via.placeholder.com/50' }}" alt="{{ $restaurant->restaurant_name }} logo" class="w-12 h-12 object-cover rounded-full">
                    <h1 class="text-xl font-semibold">{{ $restaurant->restaurant_name }} Menu</h1>
                </div>
                <div class="flex items-center space-x-4">
                    <button id="theme-toggle" class="text-white hover:text-purple-200">
                        <svg id="theme-icon" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
                        </svg>
                    </button>
                    <button id="language-toggle" class="text-white hover:text-purple-200">
                        <img src="/image/UK.png" alt="Language Flag" id="language-flag">
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

        <main class="container mx-auto px-4 py-6 flex-grow">
            <div class="mb-6">
                <div class="relative">
                    <input type="text" id="search-input" placeholder="Search items..." class="w-full p-3 pl-10 rounded-lg bg-white border border-gray-300 focus:outline-none focus:ring-2 focus:ring-purple-600 text-gray-900">
                    <svg class="absolute left-3 top-3.5 w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                    </svg>
                    <button id="clear-search" class="absolute right-3 top-3.5 text-gray-500 hidden">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
            </div>

            <div class="mb-6 overflow-x-auto whitespace-nowrap">
                <div class="flex space-x-3">
                    <button class="category-chip px-4 py-2 rounded-full bg-purple-100 text-purple-700 font-semibold hover:bg-purple-600 hover:text-white transition" data-category-id="">All</button>
                    @foreach ($categories as $category)
                        <button class="category-chip px-4 py-2 rounded-full bg-purple-100 text-purple-700 font-semibold hover:bg-purple-600 hover:text-white transition" data-category-id="{{ $category->id }}">{{ $category->name }}</button>
                    @endforeach
                </div>
            </div>

            <div id="menu-items">
                @foreach ($categories as $category)
                    @if ($category->items->isNotEmpty())
                        <div class="category-section mb-8" data-category-id="{{ $category->id }}">
                            <h2 class="text-2xl font-bold text-purple-700 mb-4">{{ $category->name }}</h2>
                            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                                @foreach ($category->items as $item)
                                    <div class="item-card bg-white rounded-lg shadow-md hover:shadow-lg transition flex items-center justify-between cursor-pointer" data-item-id="{{ $item->id }}" data-item-name="{{ $item->name }}" data-item-price="{{ $item->price }}" data-item-description="{{ $item->description ?? '' }}" data-item-image="{{ $item->image_path ? 'storage/' . $item->image_path : '' }}">
                                        <div class="flex items-center space-x-2 flex-1">
                                            <img src="{{ $item->image_path ? url('storage/' . $item->image_path) : 'https://via.placeholder.com/50' }}" alt="{{ $item->name }}" class="rounded-lg">
                                            <div>
                                                <h3 class="text-sm font-semibold text-gray-900">{{ $item->name }}</h3>
                                                <p class="text-xs text-gray-600">${{ number_format($item->price, 2) }}</p>
                                            </div>
                                        </div>
                                        <div class="quantity-selector">
                                            <button class="decrement hidden">-</button>
                                            <span class="quantity hidden">0</span>
                                            <button class="increment">+</button>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        </div>
                    @endif
                @endforeach
            </div>
        </main>

        <div id="cart-modal" class="modal fixed inset-0 bg-black bg-opacity-50 flex items-end sm:items-center justify-center hidden modal-hidden">
        <div class="bg-white rounded-t-lg sm:rounded-lg w-full sm:w-96 max-h-[80vh] overflow-y-auto">
            <div class="p-6">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-2xl font-bold text-gray-900" data-translate="your_cart">Your Cart</h2>
                    <button id="close-cart" class="text-gray-600">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <div id="cart-items" class="space-y-4"></div>
                <div class="mt-4 pt-4 border-t border-gray-300">
                    <div class="flex justify-between text-lg font-semibold text-gray-900">
                        <span data-translate="total">Total:</span>
                        <span id="cart-modal-total">$0.00</span>
                    </div>
                </div>
                <!-- Add condition to hide button when cart is empty -->
                <button id="proceed-to-table" class="w-full mt-4 bg-purple-600 text-white py-2 rounded-lg font-semibold hover:bg-purple-700 transition hidden" data-translate="proceed_to_table">Proceed to Table Number</button>
            </div>
        </div>
    </div>

        <div id="product-modal" class="modal fixed inset-0 bg-black bg-opacity-50 flex items-end sm:items-center justify-center hidden modal-hidden">
            <div class="bg-white rounded-t-lg sm:rounded-lg w-full sm:w-96 max-h-[80vh] overflow-y-auto">
                <div class="p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h2 class="text-2xl font-bold text-gray-900" id="product-name"></h2>
                        <button id="close-product" class="text-gray-600">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                            </svg>
                        </button>
                    </div>
                    <img id="product-image" src="" alt="" class="w-full h-48 rounded-lg mb-4" style="object-fit: contain; max-height: 100%; max-width: 100%;">
                    <p id="product-description" class="text-gray-600 mb-4"></p>
                    <p id="product-price" class="text-lg font-semibold text-purple-600 mb-4"></p>
                    <div class="flex items-center space-x-2 mb-4">
                        <button id="product-decrement" class="bg-purple-600 text-white rounded-full w-8 h-8 flex items-center justify-center">-</button>
                        <span id="product-quantity" class="text-gray-900">0</span>
                        <button id="product-increment" class="bg-purple-600 text-white rounded-full w-8 h-8 flex items-center justify-center">+</button>
                    </div>
                    <textarea id="product-note" placeholder="Special note (e.g., No chili...)" class="w-full p-3 rounded-lg bg-gray-100 border border-gray-300 focus:outline-none focus:ring-2 focus:ring-purple-600 text-gray-900" data-translate="special_note"></textarea>
                    <button id="add-to-cart" class="w-full mt-4 bg-purple-600 text-white py-2 rounded-lg font-semibold hover:bg-purple-700 transition" data-translate="add_to_cart">Add to Cart</button>
                </div>
            </div>
        </div>

        <div id="table-number-modal" class="modal fixed inset-0 bg-black bg-opacity-50 flex items-end sm:items-center justify-center hidden modal-hidden">
            <div class="bg-white rounded-t-lg sm:rounded-lg w-full sm:w-96 p-6">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-2xl font-bold text-gray-900" data-translate="enter_table_number">Enter Table Number</h2>
                    <button id="close-table-modal" class="text-gray-600">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <form id="table-number-form">
                    <div class="mb-4">
                        <label for="table-number" class="block text-gray-900 mb-2" data-translate="table_number">Table Number</label>
                        <input type="number" id="table-number" class="w-full p-3 rounded-lg bg-gray-100 border border-gray-300 focus:outline-none focus:ring-2 focus:ring-purple-600 text-gray-900" required min="1" step="1">
                        <p id="table-error" class="text-red-500 text-sm mt-2 hidden">
                            <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                            </svg>
                            <span>This table already has an order</span>
                        </p>
                    </div>
                    <button type="submit" id="submit-table" class="w-full bg-purple-600 text-white py-2 rounded-lg font-semibold hover:bg-purple-700 transition flex items-center justify-center" data-translate="submit_order">
                        <span>Submit Order</span>
                        <svg id="submit-loading" class="w-5 h-5 ml-2 animate-spin hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 12a8 8 0 0116 0"></path>
                        </svg>
                    </button>
                </form>
            </div>
        </div>

        <div id="confirmation-modal" class="modal fixed inset-0 bg-black bg-opacity-50 flex items-end sm:items-center justify-center hidden modal-hidden">
            <div class="bg-white rounded-t-lg sm:rounded-lg w-full sm:w-96 max-h-[80vh] overflow-y-auto">
                <div class="p-6">
                    <div class="flex justify-center mb-4">
                        <svg class="w-16 h-16 text-green-500 checkmark" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                    </div>
                    <h2 class="text-2xl font-bold text-center text-gray-900 mb-4">Thanks for supporting {{ $restaurant->restaurant_name }}!</h2>
                    <h3 id="confirmation-table-number" class="text-4xl font-bold text-center text-purple-600 mb-2"></h3>
                    <p class="text-center text-gray-600 mb-4">Please remember this number.</p>
                    <div class="mb-6">
                        <h3 class="text-lg font-semibold text-gray-900 mb-2" data-translate="your_order">Your Order</h3>
                        <ul id="ordered-items" class="space-y-4"></ul>
                        <div class="mt-4 pt-4 border-t border-gray-300">
                            <div class="flex justify-between text-lg font-semibold text-gray-900">
                                <span data-translate="total">Total:</span>
                                <span id="order-total">$0.00</span>
                            </div>
                        </div>
                    </div>
                    <button id="done-button" class="w-full bg-purple-600 text-white py-2 rounded-lg font-semibold hover:bg-purple-700 transition" data-translate="done">Done</button>
                </div>
            </div>
        </div>

        <button id="basket-button" class="hidden">Basket (0) - $0.00</button>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            console.log('DOM loaded, initializing menu...');
            let cart = JSON.parse(localStorage.getItem('cart')) || [];
            let selectedCategoryId = null;
            let currentLanguage = 'en';
            let basketTriggered = false;

            const translations = {
                en: {
                    your_cart: 'Your Cart',
                    total: 'Total',
                    proceed_to_table: 'Proceed to Table Number',
                    special_note: 'Special note (e.g., No chili...)',
                    add_to_cart: 'Add to Cart',
                    enter_table_number: 'Enter Table Number',
                    table_number: 'Table Number',
                    submit_order: 'Submit Order',
                    search_items: 'Search items...',
                    no_description: 'No description available.',
                    empty_cart_error: 'Your cart is empty',
                    order_failed: 'Failed to submit order',
                    table_number_error: 'Please enter a table number',
                    order_success: 'Order submitted successfully',
                    your_order: 'Your Order',
                    done: 'Done'
                },
                km: {
                    your_cart: 'កន្ត្រករបស់អ្នក',
                    total: 'សរុប',
                    proceed_to_table: 'បន្តទៅកាន់លេខតុ',
                    special_note: 'កំណត់ចំណាំពិសេស (ឧ. គ្មានម្ទេស...)',
                    add_to_cart: 'បន្ថែមទៅកន្ត្រក',
                    enter_table_number: 'បញ្ចូលលេខតុ',
                    table_number: 'លេខតុ',
                    submit_order: 'ដាក់បញ្ជាទិញ',
                    search_items: 'ស្វែងរកមុខម្ហូប...',
                    no_description: 'គ្មានការពិពណ៌នា',
                    empty_cart_error: 'កន្ត្រករបស់អ្នកទទេ',
                    order_failed: 'បរាជ័យក្នុងការដាក់បញ្ជាទិញ',
                    table_number_error: 'សូមបញ្ចូលលេខតុ',
                    order_success: 'ការបញ្ជាទិញបានជោគជ័យ',
                    your_order: 'ការបញ្ជាទិញរបស់អ្នក',
                    done: 'រួចរាល់'
                }
            };

            const languageFlags = {
                en: '/image/UK.png',
                km: '/image/Khmer.png'
            };

            function getImagePath(image) {
                if (!image || image === '') {
                    console.log('Image path empty, using placeholder');
                    return 'https://via.placeholder.com/50';
                }
                const path = image.startsWith('storage/') ? `/${image}` : `/storage/${image}`;
                console.log('Resolved image path:', path);
                return path;
            }

            function updateTranslations() {
                console.log('Updating translations for language:', currentLanguage);
                document.querySelectorAll('[data-translate]').forEach(element => {
                    const key = element.dataset.translate;
                    element.textContent = translations[currentLanguage][key] || element.textContent;
                });
                const searchInput = document.getElementById('search-input');
                const productNote = document.getElementById('product-note');
                if (searchInput) searchInput.placeholder = translations[currentLanguage].search_items;
                if (productNote) productNote.placeholder = translations[currentLanguage].special_note;
                document.body.className = document.body.className.replace(/\b(en|km)\b/, currentLanguage);
                const languageFlag = document.getElementById('language-flag');
                if (languageFlag) languageFlag.src = languageFlags[currentLanguage];
            }

            function toggleLanguage() {
                currentLanguage = currentLanguage === 'en' ? 'km' : 'en';
                console.log('Toggling language to:', currentLanguage);
                updateTranslations();
            }

            const themeToggle = document.getElementById('theme-toggle');
            const themeIcon = document.getElementById('theme-icon');
            if (themeToggle && themeIcon) {
                console.log('Setting up dark mode toggle');
                themeToggle.addEventListener('click', () => {
                    document.body.classList.toggle('dark');
                    localStorage.setItem('theme', document.body.classList.contains('dark') ? 'dark' : 'light');
                    themeIcon.innerHTML = document.body.classList.contains('dark') ?
                        `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"></path>` :
                        `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>`;
                    console.log('Theme set to:', document.body.classList.contains('dark') ? 'dark' : 'light');
                });
                if (localStorage.getItem('theme') === 'dark') {
                    document.body.classList.add('dark');
                    themeIcon.innerHTML = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"></path>`;
                }
            } else {
                console.error('Theme toggle elements not found:', { themeToggle, themeIcon });
            }

            function loadCart() {
                cart = JSON.parse(localStorage.getItem('cart')) || [];
                console.log('Loaded cart:', cart);
                updateCart();
                updateBasketButton();
            }

            function saveCart() {
                console.log('Saving cart:', cart);
                localStorage.setItem('cart', JSON.stringify(cart));
            }

            function updateCart() {
                const cartCount = document.getElementById('cart-count');
                const cartItemsDiv = document.getElementById('cart-items');
                const cartModalTotal = document.getElementById('cart-modal-total');
                const proceedButton = document.getElementById('proceed-to-table');

                if (!cartCount || !cartItemsDiv || !cartModalTotal || !proceedButton) {
                    console.error('Cart elements not found:', { cartCount, cartItemsDiv, cartModalTotal, proceedButton });
                    return;
                }

                const itemQuantities = cart.reduce((acc, item) => {
                    acc[item.id] = (acc[item.id] || 0) + 1;
                    return acc;
                }, {});
                const totalItems = cart.length;
                const totalPrice = cart.reduce((sum, item) => sum + item.price, 0);

                cartCount.textContent = totalItems;
                cartCount.classList.toggle('hidden', totalItems === 0);
                cartModalTotal.textContent = `$${totalPrice.toFixed(2)}`;
                
                // Show/hide proceed button based on cart items
                proceedButton.classList.toggle('hidden', totalItems === 0);

                cartItemsDiv.innerHTML = '';
                Object.entries(itemQuantities).forEach(([itemId, quantity]) => {
                    const item = cart.find(i => i.id == itemId);
                    const div = document.createElement('div');
                    div.className = 'flex items-center justify-between p-2 bg-gray-100 dark:bg-gray-700 rounded-lg';
                    div.innerHTML = `
                        <div class="flex items-center space-x-2">
                            <img src="${getImagePath(item.image)}" alt="${item.name}" class="w-12 h-12 object-cover rounded-lg">
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
                            saveCart();
                            updateCart();
                            updateBasketButton();
                        }
                    });
                });

                document.querySelectorAll('#cart-items .increment').forEach(btn => {
                    btn.addEventListener('click', () => {
                        const itemId = btn.dataset.itemId;
                        const item = cart.find(item => item.id == itemId);
                        cart.push({ ...item });
                        saveCart();
                        updateCart();
                        updateBasketButton();
                    });
                });

                document.querySelectorAll('.item-card').forEach(card => {
                    const itemId = card.dataset.itemId;
                    const quantity = itemQuantities[itemId] || 0;
                    const decrement = card.querySelector('.decrement');
                    const quantityElem = card.querySelector('.quantity');
                    const increment = card.querySelector('.increment');
                    quantityElem.textContent = quantity;
                    if (quantity > 0) {
                        decrement.classList.remove('hidden');
                        quantityElem.classList.remove('hidden');
                    } else {
                        decrement.classList.add('hidden');
                        quantityElem.classList.add('hidden');
                    }
                });
            }

            function updateBasketButton() {
                const basketButton = document.getElementById('basket-button');
                if (!basketButton) {
                    console.error('Basket button not found');
                    return;
                }

                const totalItems = cart.length;
                const totalPrice = cart.reduce((sum, item) => sum + item.price, 0);
                basketButton.textContent = `Basket (${totalItems}) - $${totalPrice.toFixed(2)}`;

                if (basketTriggered && totalItems > 0) {
                    basketButton.classList.remove('hidden');
                } else {
                    basketButton.classList.add('hidden');
                }
            }

            function showConfirmationModal(tableNumber) {
                const confirmationModal = document.getElementById('confirmation-modal');
                const orderedItemsDiv = document.getElementById('ordered-items');
                const orderTotal = document.getElementById('order-total');
                const confirmationTable = document.getElementById('confirmation-table-number');

                if (!confirmationModal || !orderedItemsDiv || !orderTotal || !confirmationTable) {
                    console.error('Confirmation modal elements not found');
                    return;
                }

                confirmationTable.textContent = `Table ${tableNumber}`;

                const itemQuantities = cart.reduce((acc, item) => {
                    const key = `${item.id}-${item.note || ''}`;
                    if (!acc[key]) {
                        acc[key] = { ...item, quantity: 0 };
                    }
                    acc[key].quantity++;
                    return acc;
                }, {});

                const totalPrice = cart.reduce((sum, item) => sum + item.price, 0);
                orderTotal.textContent = `$${totalPrice.toFixed(2)}`;

                orderedItemsDiv.innerHTML = Object.values(itemQuantities).map(item => `
                    <li class="flex items-center justify-between p-2 bg-gray-100 dark:bg-gray-700 rounded-lg">
                        <div class="flex items-center space-x-2">
                            <img src="${getImagePath(item.image)}" alt="${item.name}" class="w-12 h-12 object-cover rounded-lg">
                            <div>
                                <p class="font-semibold text-gray-900 dark:text-white">${item.name}</p>
                                ${item.note ? `<p class="text-sm text-gray-500 dark:text-gray-400">Note: ${item.note}</p>` : ''}
                            </div>
                        </div>
                        <span class="text-gray-600 dark:text-gray-400">$${item.price.toFixed(2)} x ${item.quantity}</span>
                    </li>
                `).join('');

                confirmationModal.classList.remove('hidden', 'modal-hidden');
                updateTranslations();
            }

            document.querySelectorAll('.item-card').forEach(card => {
                card.addEventListener('click', () => {
                    const item = {
                        id: card.dataset.itemId,
                        name: card.dataset.itemName,
                        price: parseFloat(card.dataset.itemPrice),
                        description: card.dataset.itemDescription,
                        image: card.dataset.itemImage || '',
                        note: ''
                    };
                    console.log('Opening product modal for item:', item);
                    const productName = document.getElementById('product-name');
                    const productPrice = document.getElementById('product-price');
                    const productDescription = document.getElementById('product-description');
                    const productImage = document.getElementById('product-image');
                    const productNote = document.getElementById('product-note');
                    const productQuantity = document.getElementById('product-quantity');

                    if (!productName || !productPrice || !productDescription || !productImage || !productNote || !productQuantity) {
                        console.error('Product modal elements not found:', { productName, productPrice, productDescription, productImage, productNote, productQuantity });
                        return;
                    }

                    productName.textContent = item.name;
                    productPrice.textContent = `$${item.price.toFixed(2)}`;
                    productDescription.textContent = item.description || translations[currentLanguage].no_description;
                    productImage.src = getImagePath(item.image);
                    productNote.value = cart.find(i => i.id == item.id)?.note || '';
                    const quantity = cart.filter(i => i.id == item.id).length;
                    productQuantity.textContent = quantity;

                    const modal = document.getElementById('product-modal');
                    if (modal) {
                        modal.classList.remove('hidden', 'modal-hidden');
                        document.getElementById('basket-button').classList.add('hidden');
                        updateTranslations();
                    } else {
                        console.error('Product modal not found');
                    }

                    document.getElementById('product-increment').onclick = () => {
                        cart.push({ ...item, note: productNote.value });
                        saveCart();
                        updateCart();
                        productQuantity.textContent = cart.filter(i => i.id == item.id).length;
                    };
                    document.getElementById('product-decrement').onclick = () => {
                        const index = cart.findIndex(i => i.id == item.id);
                        if (index !== -1) {
                            cart.splice(index, 1);
                            saveCart();
                            updateCart();
                            productQuantity.textContent = cart.filter(i => i.id == item.id).length;
                        }
                    };
                    document.getElementById('add-to-cart').onclick = () => {
                        const note = productNote.value;
                        cart.filter(i => i.id == item.id).forEach(i => i.note = note);
                        saveCart();
                        updateCart();
                        modal.classList.add('hidden');
                        setTimeout(() => modal.classList.add('modal-hidden'), 300);
                    };
                });

                const decrement = card.querySelector('.decrement');
                const increment = card.querySelector('.increment');

                decrement.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const itemId = card.dataset.itemId;
                    const index = cart.findIndex(item => item.id == itemId);
                    if (index !== -1) {
                        cart.splice(index, 1);
                        saveCart();
                        updateCart();
                        updateBasketButton();
                        if (cart.length === 0) basketTriggered = false;
                    }
                });

                increment.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const item = {
                        id: card.dataset.itemId,
                        name: card.dataset.itemName,
                        price: parseFloat(card.dataset.itemPrice),
                        description: card.dataset.itemDescription,
                        image: card.dataset.itemImage || '',
                        note: cart.find(i => i.id == card.dataset.itemId)?.note || ''
                    };
                    cart.push(item);
                    saveCart();
                    updateCart();
                    basketTriggered = true;
                    updateBasketButton();
                });
            });

            document.getElementById('search-input').addEventListener('input', () => {
                const searchInput = document.getElementById('search-input');
                const clearSearch = document.getElementById('clear-search');
                if (!searchInput || !clearSearch) {
                    console.error('Search elements not found:', { searchInput, clearSearch });
                    return;
                }
                const searchText = searchInput.value.toLowerCase();
                clearSearch.classList.toggle('hidden', !searchText);
                document.querySelectorAll('.item-card').forEach(card => {
                    const name = card.dataset.itemName.toLowerCase();
                    card.closest('.category-section').classList.toggle('hidden', !name.includes(searchText) && selectedCategoryId);
                    card.classList.toggle('hidden', !name.includes(searchText));
                });
            });

            document.getElementById('clear-search').addEventListener('click', () => {
                const searchInput = document.getElementById('search-input');
                const clearSearch = document.getElementById('clear-search');
                if (searchInput && clearSearch) {
                    searchInput.value = '';
                    clearSearch.classList.add('hidden');
                    document.querySelectorAll('.item-card, .category-section').forEach(el => el.classList.remove('hidden'));
                } else {
                    console.error('Clear search elements not found:', { searchInput, clearSearch });
                }
            });

            document.querySelectorAll('.category-chip').forEach(chip => {
                chip.addEventListener('click', () => {
                    document.querySelectorAll('.category-chip').forEach(c => c.classList.remove('bg-purple-600', 'text-white'));
                    chip.classList.add('bg-purple-600', 'text-white');
                    selectedCategoryId = chip.dataset.categoryId || null;
                    document.querySelectorAll('.category-section').forEach(section => {
                        section.classList.toggle('hidden', selectedCategoryId && section.dataset.categoryId !== selectedCategoryId);
                    });
                    const searchInput = document.getElementById('search-input');
                    const clearSearch = document.getElementById('clear-search');
                    if (searchInput && clearSearch) {
                        searchInput.value = '';
                        clearSearch.classList.add('hidden');
                    }
                });
            });

            document.getElementById('close-product').addEventListener('click', () => {
                const modal = document.getElementById('product-modal');
                if (modal) {
                    modal.classList.add('hidden');
                    setTimeout(() => modal.classList.add('modal-hidden'), 300);
                    updateBasketButton();
                } else {
                    console.error('Product modal not found for close');
                }
            });

            document.getElementById('cart-toggle').addEventListener('click', () => {
                const modal = document.getElementById('cart-modal');
                const basketButton = document.getElementById('basket-button');
                if (modal && basketButton) {
                    modal.classList.remove('hidden', 'modal-hidden');
                    basketButton.classList.add('hidden');
                    updateTranslations();
                } else {
                    console.error('Cart modal or basket button not found');
                }
            });

            document.getElementById('basket-button').addEventListener('click', () => {
                const modal = document.getElementById('cart-modal');
                const basketButton = document.getElementById('basket-button');
                if (modal && basketButton) {
                    modal.classList.remove('hidden', 'modal-hidden');
                    basketButton.classList.add('hidden');
                    updateTranslations();
                } else {
                    console.error('Cart modal or basket button not found');
                }
            });

            document.getElementById('close-cart').addEventListener('click', () => {
                const modal = document.getElementById('cart-modal');
                if (modal) {
                    modal.classList.add('hidden');
                    setTimeout(() => modal.classList.add('modal-hidden'), 300);
                    updateBasketButton();
                } else {
                    console.error('Cart modal not found for close');
                }
            });

            document.getElementById('proceed-to-table').addEventListener('click', () => {
                const cartModal = document.getElementById('cart-modal');
                const tableModal = document.getElementById('table-number-modal');
                if (cartModal && tableModal) {
                    cartModal.classList.add('hidden');
                    setTimeout(() => cartModal.classList.add('modal-hidden'), 300);
                    tableModal.classList.remove('hidden', 'modal-hidden');
                    updateTranslations();
                } else {
                    console.error('Modal elements not found:', { cartModal, tableModal });
                }
            });

            document.getElementById('close-table-modal').addEventListener('click', () => {
                const modal = document.getElementById('table-number-modal');
                if (modal) {
                    modal.classList.add('hidden');
                    setTimeout(() => modal.classList.add('modal-hidden'), 300);
                } else {
                    console.error('Table modal not found for close');
                }
            });

            document.getElementById('language-toggle').addEventListener('click', toggleLanguage);

            document.getElementById('done-button').addEventListener('click', () => {
                const modal = document.getElementById('confirmation-modal');
                if (modal) {
                    modal.classList.add('hidden');
                    setTimeout(() => modal.classList.add('modal-hidden'), 300);
                    cart = [];
                    saveCart();
                    updateCart();
                    updateBasketButton();
                    basketTriggered = false;
                } else {
                    console.error('Confirmation modal not found for close');
                }
            });

            const tableNumberInput = document.getElementById('table-number');
            if (tableNumberInput) {
                // Clear any existing error when input is focused
                tableNumberInput.addEventListener('focus', () => {
                    const errorDiv = document.getElementById('table-error');
                    errorDiv.classList.add('hidden');
                    tableNumberInput.classList.remove('border-red-500');
                });
                
                tableNumberInput.addEventListener('input', async () => {
                    const tableNumber = tableNumberInput.value.trim();
                    const errorDiv = document.getElementById('table-error');
                    
                    // Don't validate if input is empty
                    if (!tableNumber) {
                        errorDiv.classList.add('hidden');
                        tableNumberInput.classList.remove('border-red-500');
                        return;
                    }
                    
                    try {
                        const response = await axios.get(`{{ route('web.check-table', ['id' => $restaurant->id]) }}?table_number=${tableNumber}`);
                        if (!response.data.available) {
                            errorDiv.classList.remove('hidden');
                            tableNumberInput.classList.add('border-red-500');
                        } else {
                            errorDiv.classList.add('hidden');
                            tableNumberInput.classList.remove('border-red-500');
                        }
                    } catch (error) {
                        console.error('Table check error:', error);
                    }
                });
            }

            const tableNumberForm = document.getElementById('table-number-form');
            if (tableNumberForm) {
                tableNumberForm.addEventListener('submit', async (e) => {
                    e.preventDefault();
                    const tableNumberInput = document.getElementById('table-number');
                    const submitButton = document.getElementById('submit-table');
                    const loadingIcon = document.getElementById('submit-loading');
                    const errorDiv = document.getElementById('table-error');

                    if (!tableNumberInput || !submitButton || !errorDiv) {
                        console.error('Critical order form elements missing:', { tableNumberInput, submitButton, loadingIcon, errorDiv });
                        return;
                    }

                    const tableNumber = tableNumberInput.value.trim();
                    const tableNumberInt = parseInt(tableNumber, 10);
                    if (!tableNumber || isNaN(tableNumberInt) || tableNumberInt <= 0) {
                        errorDiv.textContent = translations[currentLanguage].table_number_error || 'Please enter a valid table number';
                        errorDiv.classList.remove('hidden');
                        return;
                    }

                    if (cart.length === 0) {
                        errorDiv.textContent = translations[currentLanguage].empty_cart_error || 'Your cart is empty';
                        errorDiv.classList.remove('hidden');
                        return;
                    }

                    const items = cart.reduce((acc, item) => {
                        const itemId = parseInt(item.id, 10);
                        if (isNaN(itemId)) {
                            console.warn('Skipping invalid item_id:', item.id);
                            return acc;
                        }
                        const existing = acc.find(i => i.item_id === itemId && i.special_note === (item.note || null));
                        if (existing) {
                            existing.quantity++;
                        } else {
                            acc.push({
                                item_id: itemId,
                                quantity: 1,
                                special_note: item.note || null
                            });
                        }
                        return acc;
                    }, []);

                    if (items.length === 0) {
                        errorDiv.textContent = translations[currentLanguage].empty_cart_error || 'No valid items in cart';
                        errorDiv.classList.remove('hidden');
                        return;
                    }

                    const payload = { table_number: tableNumberInt, items };
                    submitButton.disabled = true;
                    if (loadingIcon) loadingIcon.classList.remove('hidden');
                    errorDiv.classList.add('hidden');

                    try {
                        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
                        if (!csrfToken) throw new Error('CSRF token not found');
                        const response = await axios.post('{{ route('web.submit-order', ['id' => $restaurant->id]) }}', payload, {
                            headers: { 'X-CSRF-TOKEN': csrfToken }
                        });

                        if (response.status === 201) {
                            localStorage.removeItem('cart');
                            updateCart();
                            updateBasketButton();
                            const tableModal = document.getElementById('table-number-modal');
                            if (tableModal) {
                                tableModal.classList.add('hidden');
                                setTimeout(() => tableModal.classList.add('modal-hidden'), 300);
                            }
                            showConfirmationModal(tableNumberInt);
                        } else {
                            throw new Error('Unexpected response status');
                        }
                    } catch (error) {
                        console.error('Order submission error:', error);
                        const errorMessage = error.response?.data?.error || error.response?.data?.message || translations[currentLanguage].order_failed || 'Failed to submit order';
                        errorDiv.textContent = errorMessage;
                        errorDiv.classList.remove('hidden');
                        errorDiv.classList.add('text-red-500');
                    } finally {
                        submitButton.disabled = false;
                        if (loadingIcon) loadingIcon.classList.add('hidden');
                    }
                });
            }

            loadCart();
            updateTranslations();
        });
    </script>
</body>
</html>