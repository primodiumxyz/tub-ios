export type CoinData = {
  name: string;
  symbol: string;
};


export const generateRandomMemecoin = (): CoinData => {
  const prefixes = ["Fluffy", "Doge", "Shiba", "Moon", "Paw", "Meme", "Wag", "Bark", "Cheems", "Pup", "Frog", "Cat", "Coin", "Toad", "Pepe", "Lambo", "Hodl", "Snoop", "Bunny", "Ninja", "Rocket", "Chill", "Vibe", "Squad", "Gang"];
  const suffixes = ["Coin", "Token", "Cash", "Dollars", "Bucks", "Credits", "Cash", "Loot", "Bits", "Cash", "Dough", "Moola", "Dimes", "Dollars", "Bling", "Loot", "Stash", "Wealth", "Riches", "Gold", "Silver", "Platinum", "Gems", "Treasure", "Fortune", "Assets"];
  const middleParts = ["Super", "Mega", "Ultra", "Hyper", "Epic", "Legendary", "Cosmic", "Galactic", "Quantum", "Virtual", "Digital", "Crypto", "Future", "NextGen", "Smart", "Fast", "Quick", "Swift", "Turbo", "Power", "Max", "Prime", "Elite", "Pro", "Xtreme", "Infinity"];

  const randomPrefix = prefixes[Math.floor(Math.random() * prefixes.length)];
  const randomSuffix = suffixes[Math.floor(Math.random() * suffixes.length)];
  const randomMiddle = middleParts[Math.floor(Math.random() * middleParts.length)];

  const coinName = `${randomPrefix} ${randomMiddle} ${randomSuffix}`;
  const symbol = randomPrefix;

  return { name: coinName, symbol };
};