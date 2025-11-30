<!DOCTYPE html>
<html lang="cs">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="theme-color" content="#4F46E5">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <title>Kantýna - Objednávky</title>
    <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        * {
            -webkit-tap-highlight-color: transparent;
        }
        body {
            overscroll-behavior: none;
            touch-action: pan-y;
        }
        .fade-in {
            animation: fadeIn 0.3s ease-in;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .slide-up {
            animation: slideUp 0.4s ease-out;
        }
        @keyframes slideUp {
            from { transform: translateY(100%); }
            to { transform: translateY(0); }
        }
    </style>
</head>
<body class="bg-gray-50">
    <div id="root"></div>

    <script type="text/babel">
        const { useState, useEffect } = React;

        // Simulace localStorage databáze
        const DB = {
            getMenu: () => {
                const menu = localStorage.getItem('menu');
                return menu ? JSON.parse(menu) : [
                    { id: 1, name: 'Smažený řízek s bramborovou kaší', price: 85, category: 'Hlavní jídlo', available: true },
                    { id: 2, name: 'Kuřecí kung-pao s rýží', price: 75, category: 'Hlavní jídlo', available: true },
                    { id: 3, name: 'Bramboračka s klobásou', price: 45, category: 'Polévka', available: true },
                    { id: 4, name: 'Čočková polévka', price: 40, category: 'Polévka', available: true },
                    { id: 5, name: 'Jablečný závin', price: 30, category: 'Dezert', available: true }
                ];
            },
            saveMenu: (menu) => {
                localStorage.setItem('menu', JSON.stringify(menu));
            },
            getOrders: () => {
                const orders = localStorage.getItem('orders');
                return orders ? JSON.parse(orders) : [];
            },
            saveOrder: (order) => {
                const orders = DB.getOrders();
                orders.push(order);
                localStorage.setItem('orders', JSON.stringify(orders));
                return order;
            },
            updateOrder: (orderId, updates) => {
                const orders = DB.getOrders();
                const index = orders.findIndex(o => o.id === orderId);
                if (index !== -1) {
                    orders[index] = { ...orders[index], ...updates };
                    localStorage.setItem('orders', JSON.stringify(orders));
                }
            },
            deleteOrder: (orderId) => {
                let orders = DB.getOrders();
                orders = orders.filter(o => o.id !== orderId);
                localStorage.setItem('orders', JSON.stringify(orders));
            }
        };

        // Hlavní komponenta
        function App() {
            const [view, setView] = useState('customer'); // 'customer' nebo 'admin'
            const [isAdminAuth, setIsAdminAuth] = useState(false);

            return (
                <div className="min-h-screen pb-20">
                    {view === 'customer' ? (
                        <CustomerView onAdminClick={() => setView('admin')} />
                    ) : (
                        <AdminView 
                            isAuth={isAdminAuth} 
                            onAuth={setIsAdminAuth}
                            onBack={() => setView('customer')} 
                        />
                    )}
                </div>
            );
        }

        // Zákaznické rozhraní
        function CustomerView({ onAdminClick }) {
            const [step, setStep] = useState('menu'); // 'menu', 'order', 'confirm'
            const [cart, setCart] = useState([]);
            const [customerName, setCustomerName] = useState('');
            const [pickupTime, setPickupTime] = useState('12:00');
            const [orderConfirmed, setOrderConfirmed] = useState(null);

            const menu = DB.getMenu().filter(item => item.available);

            const addToCart = (item) => {
                const existing = cart.find(c => c.id === item.id);
                if (existing) {
                    setCart(cart.map(c => c.id === item.id ? { ...c, quantity: c.quantity + 1 } : c));
                } else {
                    setCart([...cart, { ...item, quantity: 1 }]);
                }
            };

            const removeFromCart = (itemId) => {
                const existing = cart.find(c => c.id === itemId);
                if (existing.quantity > 1) {
                    setCart(cart.map(c => c.id === itemId ? { ...c, quantity: c.quantity - 1 } : c));
                } else {
                    setCart(cart.filter(c => c.id !== itemId));
                }
            };

            const totalPrice = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);

            const submitOrder = () => {
                if (!customerName.trim()) {
                    alert('Prosím vyplň své jméno');
                    return;
                }
                if (cart.length === 0) {
                    alert('Košík je prázdný');
                    return;
                }

                const order = {
                    id: Date.now(),
                    customerName: customerName.trim(),
                    items: cart,
                    pickupTime,
                    totalPrice,
                    status: 'pending',
                    createdAt: new Date().toISOString(),
                    pin: Math.floor(1000 + Math.random() * 9000)
                };

                DB.saveOrder(order);
                setOrderConfirmed(order);
                setCart([]);
                setCustomerName('');
                setStep('confirm');
            };

            if (step === 'confirm' && orderConfirmed) {
                return (
                    <div className="slide-up">
                        <div className="bg-gradient-to-r from-indigo-600 to-purple-600 text-white p-6 text-center">
                            <div className="text-6xl mb-4">✓</div>
                            <h1 className="text-2xl font-bold mb-2">Objednávka přijata!</h1>
                            <p className="opacity-90">Tvé jídlo bude připraveno</p>
                        </div>

                        <div className="p-6">
                            <div className="bg-white rounded-2xl shadow-lg p-6 mb-6">
                                <div className="text-center mb-6">
                                    <p className="text-gray-600 mb-2">Tvůj PIN kód</p>
                                    <div className="text-5xl font-bold text-indigo-600 mb-2">{orderConfirmed.pin}</div>
                                    <p className="text-sm text-gray-500">Ukaž tento kód při vyzvednutí</p>
                                </div>

                                <div className="border-t pt-4">
                                    <div className="flex justify-between mb-2">
                                        <span className="text-gray-600">Jméno:</span>
                                        <span className="font-semibold">{orderConfirmed.customerName}</span>
                                    </div>
                                    <div className="flex justify-between mb-2">
                                        <span className="text-gray-600">Čas vyzvednutí:</span>
                                        <span className="font-semibold">{orderConfirmed.pickupTime}</span>
                                    </div>
                                    <div className="flex justify-between mb-4">
                                        <span className="text-gray-600">Cena k úhradě:</span>
                                        <span className="font-bold text-lg text-indigo-600">{orderConfirmed.totalPrice} Kč</span>
                                    </div>
                                </div>

                                <div className="border-t pt-4">
                                    <p className="font-semibold mb-2">Tvá objednávka:</p>
                                    {orderConfirmed.items.map(item => (
                                        <div key={item.id} className="flex justify-between text-sm mb-1">
                                            <span>{item.quantity}× {item.name}</span>
                                            <span>{item.price * item.quantity} Kč</span>
                                        </div>
                                    ))}
                                </div>
                            </div>

                            <button
                                onClick={() => {
                                    setStep('menu');
                                    setOrderConfirmed(null);
                                }}
                                className="w-full bg-indigo-600 text-white py-4 rounded-xl font-semibold text-lg shadow-lg"
                            >
                                Zpět do menu
                            </button>
                        </div>
                    </div>
                );
            }

            return (
                <div className="fade-in">
                    <div className="bg-gradient-to-r from-indigo-600 to-purple-600 text-white p-6 sticky top-0 z-10 shadow-lg">
                        <div className="flex justify-between items-center">
                            <div>
                                <h1 className="text-2xl font-bold">Kantýna</h1>
                                <p className="text-sm opacity-90">Dnešní menu</p>
                            </div>
                            <button
                                onClick={onAdminClick}
                                className="bg-white/20 px-4 py-2 rounded-lg text-sm"
                            >
                                Admin
                            </button>
                        </div>
                    </div>

                    <div className="p-4">
                        {['Polévka', 'Hlavní jídlo', 'Dezert'].map(category => {
                            const items = menu.filter(item => item.category === category);
                            if (items.length === 0) return null;

                            return (
                                <div key={category} className="mb-6">
                                    <h2 className="text-lg font-bold text-gray-800 mb-3 px-2">{category}</h2>
                                    <div className="space-y-3">
                                        {items.map(item => {
                                            const inCart = cart.find(c => c.id === item.id);
                                            return (
                                                <div key={item.id} className="bg-white rounded-xl shadow-md p-4">
                                                    <div className="flex justify-between items-start mb-3">
                                                        <div className="flex-1">
                                                            <h3 className="font-semibold text-gray-800">{item.name}</h3>
                                                            <p className="text-indigo-600 font-bold mt-1">{item.price} Kč</p>
                                                        </div>
                                                    </div>
                                                    
                                                    {inCart ? (
                                                        <div className="flex items-center justify-between bg-indigo-50 rounded-lg p-2">
                                                            <button
                                                                onClick={() => removeFromCart(item.id)}
                                                                className="bg-white w-10 h-10 rounded-lg shadow flex items-center justify-center text-xl font-bold text-indigo-600"
                                                            >
                                                                -
                                                            </button>
                                                            <span className="font-bold text-lg">{inCart.quantity}</span>
                                                            <button
                                                                onClick={() => addToCart(item)}
                                                                className="bg-indigo-600 w-10 h-10 rounded-lg shadow flex items-center justify-center text-xl font-bold text-white"
                                                            >
                                                                +
                                                            </button>
                                                        </div>
                                                    ) : (
                                                        <button
                                                            onClick={() => addToCart(item)}
                                                            className="w-full bg-indigo-600 text-white py-3 rounded-lg font-semibold shadow-md"
                                                        >
                                                            Přidat do košíku
                                                        </button>
                                                    )}
                                                </div>
                                            );
                                        })}
                                    </div>
                                </div>
                            );
                        })}
                    </div>

                    {cart.length > 0 && (
                        <div className="fixed bottom-0 left-0 right-0 bg-white border-t shadow-2xl slide-up">
                            <div className="p-4">
                                <div className="mb-4">
                                    <label className="block text-sm font-semibold text-gray-700 mb-2">Tvé jméno</label>
                                    <input
                                        type="text"
                                        value={customerName}
                                        onChange={(e) => setCustomerName(e.target.value)}
                                        placeholder="Zadej své jméno"
                                        className="w-full border-2 border-gray-300 rounded-lg px-4 py-3 text-lg"
                                    />
                                </div>

                                <div className="mb-4">
                                    <label className="block text-sm font-semibold text-gray-700 mb-2">Čas vyzvednutí</label>
                                    <select
                                        value={pickupTime}
                                        onChange={(e) => setPickupTime(e.target.value)}
                                        className="w-full border-2 border-gray-300 rounded-lg px-4 py-3 text-lg"
                                    >
                                        <option value="11:30">11:30</option>
                                        <option value="12:00">12:00</option>
                                        <option value="12:30">12:30</option>
                                        <option value="13:00">13:00</option>
                                        <option value="13:30">13:30</option>
                                    </select>
                                </div>

                                <div className="flex justify-between items-center mb-4">
                                    <span className="text-gray-600">Celkem k úhradě:</span>
                                    <span className="text-2xl font-bold text-indigo-600">{totalPrice} Kč</span>
                                </div>

                                <button
                                    onClick={submitOrder}
                                    className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white py-4 rounded-xl font-bold text-lg shadow-xl"
                                >
                                    Objednat ({cart.length} {cart.length === 1 ? 'položka' : cart.length < 5 ? 'položky' : 'položek'})
                                </button>
                            </div>
                        </div>
                    )}
                </div>
            );
        }

        // Admin rozhraní
        function AdminView({ isAuth, onAuth, onBack }) {
            const [password, setPassword] = useState('');
            const [activeTab, setActiveTab] = useState('orders'); // 'orders' nebo 'menu'
            const [orders, setOrders] = useState([]);
            const [menu, setMenu] = useState([]);
            const [editingItem, setEditingItem] = useState(null);

            useEffect(() => {
                if (isAuth) {
                    loadData();
                }
            }, [isAuth]);

            const loadData = () => {
                setOrders(DB.getOrders().sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
                setMenu(DB.getMenu());
            };

            const handleLogin = () => {
                if (password === 'admin123') {
                    onAuth(true);
                } else {
                    alert('Špatné heslo!');
                }
            };

            const markAsCompleted = (orderId) => {
                DB.updateOrder(orderId, { status: 'completed' });
                loadData();
            };

            const deleteOrder = (orderId) => {
                if (confirm('Opravdu smazat tuto objednávku?')) {
                    DB.deleteOrder(orderId);
                    loadData();
                }
            };

            const toggleMenuItemAvailability = (itemId) => {
                const updatedMenu = menu.map(item => 
                    item.id === itemId ? { ...item, available: !item.available } : item
                );
                DB.saveMenu(updatedMenu);
                loadData();
            };

            if (!isAuth) {
                return (
                    <div className="min-h-screen bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center p-6">
                        <div className="bg-white rounded-2xl shadow-2xl p-8 w-full max-w-md">
                            <h2 className="text-3xl font-bold text-gray-800 mb-6 text-center">Admin přihlášení</h2>
                            <input
                                type="password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                onKeyPress={(e) => e.key === 'Enter' && handleLogin()}
                                placeholder="Zadej heslo"
                                className="w-full border-2 border-gray-300 rounded-lg px-4 py-3 mb-4 text-lg"
                            />
                            <button
                                onClick={handleLogin}
                                className="w-full bg-indigo-600 text-white py-3 rounded-lg font-bold text-lg mb-3"
                            >
                                Přihlásit se
                            </button>
                            <button
                                onClick={onBack}
                                className="w-full bg-gray-200 text-gray-700 py-3 rounded-lg font-semibold"
                            >
                                Zpět
                            </button>
                            <p className="text-sm text-gray-500 text-center mt-4">Výchozí heslo: admin123</p>
                        </div>
                    </div>
                );
            }

            const todayOrders = orders.filter(order => {
                const orderDate = new Date(order.createdAt).toDateString();
                const today = new Date().toDateString();
                return orderDate === today;
            });

            const pendingOrders = todayOrders.filter(o => o.status === 'pending');
            const completedOrders = todayOrders.filter(o => o.status === 'completed');

            return (
                <div className="fade-in">
                    <div className="bg-gradient-to-r from-gray-800 to-gray-900 text-white p-6 sticky top-0 z-10 shadow-lg">
                        <div className="flex justify-between items-center mb-4">
                            <h1 className="text-2xl font-bold">Admin panel</h1>
                            <button
                                onClick={() => {
                                    onAuth(false);
                                    onBack();
                                }}
                                className="bg-white/20 px-4 py-2 rounded-lg text-sm"
                            >
                                Odhlásit
                            </button>
                        </div>
                        
                        <div className="flex gap-2">
                            <button
                                onClick={() => setActiveTab('orders')}
                                className={`flex-1 py-2 rounded-lg font-semibold ${activeTab === 'orders' ? 'bg-white text-gray-900' : 'bg-white/20'}`}
                            >
                                Objednávky ({pendingOrders.length})
                            </button>
                            <button
                                onClick={() => setActiveTab('menu')}
                                className={`flex-1 py-2 rounded-lg font-semibold ${activeTab === 'menu' ? 'bg-white text-gray-900' : 'bg-white/20'}`}
                            >
                                Menu
                            </button>
                        </div>
                    </div>

                    <div className="p-4">
                        {activeTab === 'orders' ? (
                            <>
                                {pendingOrders.length === 0 ? (
                                    <div className="text-center py-12 text-gray-500">
                                        <div className="text-6xl mb-4">📋</div>
                                        <p className="text-lg">Zatím žádné čekající objednávky</p>
                                    </div>
                                ) : (
                                    <>
                                        <h2 className="text-xl font-bold text-gray-800 mb-4">Čekající objednávky</h2>
                                        <div className="space-y-4 mb-8">
                                            {pendingOrders.map(order => (
                                                <div key={order.id} className="bg-white rounded-xl shadow-lg p-5 border-l-4 border-orange-500">
                                                    <div className="flex justify-between items-start mb-3">
                                                        <div>
                                                            <div className="text-3xl font-bold text-orange-600 mb-1">{order.pin}</div>
                                                            <p className="font-semibold text-lg">{order.customerName}</p>
                                                            <p className="text-sm text-gray-600">Vyzvednutí: {order.pickupTime}</p>
                                                        </div>
                                                        <div className="text-right">
                                                            <p className="text-2xl font-bold text-indigo-600">{order.totalPrice} Kč</p>
                                                            <p className="text-xs text-gray-500">{new Date(order.createdAt).toLocaleTimeString('cs-CZ')}</p>
                                                        </div>
                                                    </div>
                                                    
                                                    <div className="border-t pt-3 mb-3">
                                                        {order.items.map(item => (
                                                            <div key={item.id} className="flex justify-between text-sm mb-1">
                                                                <span>{item.quantity}× {item.name}</span>
                                                                <span className="text-gray-600">{item.price * item.quantity} Kč</span>
                                                            </div>
                                                        ))}
                                                    </div>

                                                    <div className="flex gap-2">
                                                        <button
                                                            onClick={() => markAsCompleted(order.id)}
                                                            className="flex-1 bg-green-600 text-white py-3 rounded-lg font-semibold"
                                                        >
                                                            ✓ Vyzvednuto
                                                        </button>
                                                        <button
                                                            onClick={() => deleteOrder(order.id)}
                                                            className="bg-red-600 text-white px-4 py-3 rounded-lg font-semibold"
                                                        >
                                                            ×
                                                        </button>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </>
                                )}

                                {completedOrders.length > 0 && (
                                    <>
                                        <h2 className="text-xl font-bold text-gray-800 mb-4">Dokončené dnes</h2>
                                        <div className="space-y-3">
                                            {completedOrders.map(order => (
                                                <div key={order.id} className="bg-gray-100 rounded-lg p-4 opacity-60">
                                                    <div className="flex justify-between">
                                                        <div>
                                                            <p className="font-semibold">{order.customerName}</p>
                                                            <p className="text-sm text-gray-600">{order.pickupTime}</p>
                                                        </div>
                                                        <div className="text-right">
                                                            <p className="font-bold">{order.totalPrice} Kč</p>
                                                            <p className="text-xs text-green-600">✓ Vyzvednuto</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </>
                                )}
                            </>
                        ) : (
                            <>
                                <h2 className="text-xl font-bold text-gray-800 mb-4">Správa menu</h2>
                                <div className="space-y-3">
                                    {menu.map(item => (
                                        <div key={item.id} className={`bg-white rounded-xl shadow-md p-4 ${!item.available ? 'opacity-50' : ''}`}>
                                            <div className="flex justify-between items-start mb-3">
                                                <div className="flex-1">
                                                    <span className="text-xs font-semibold text-gray-500 uppercase">{item.category}</span>
                                                    <h3 className="font-semibold text-gray-800">{item.name}</h3>
                                                    <p className="text-indigo-600 font-bold">{item.price} Kč</p>
                                                </div>
                                            </div>
                                            
                                            <button
                                                onClick={() => toggleMenuItemAvailability(item.id)}
                                                className={`w-full py-2 rounded-lg font-semibold ${item.available ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}
                                            >
                                                {item.available ? '× Skrýt z nabídky' : '✓ Zobrazit v nabídce'}
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            </>
                        )}
                    </div>
                </div>
            );
        }

        // Spuštění aplikace
        ReactDOM.render(<App />, document.getElementById('root'));
    </script>
</body>
</html>
