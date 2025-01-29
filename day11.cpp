#include <iostream>
#include <vector>
#include <map>

long long part_two() {
    std::unordered_map<long long, long long> stones {{41078, 1}, {18, 1}, {7, 1}, {0, 1}, {4785508, 1}, {535256, 1}, {8154, 1}, {447, 1}};
    for (int i = 0; i < 75; i++) {
        std::unordered_map<long long, long long> new_stones;
        for (std::pair<long long, long long> stone : stones) {
            std::string temp = std::to_string(stone.first);
            if (stone.first == 0) {
                new_stones[1] += stone.second;
            } else if (temp.length() % 2 == 0) {
                new_stones[std::stoll(temp.substr(0, temp.length() / 2))] += stone.second;
                new_stones[std::stoll(temp.substr(temp.length() / 2, temp.length() / 2))] += stone.second;
            } else {
                new_stones[stone.first * 2024] += stone.second;
            }
        }
        stones = new_stones;
    }
    long long res = 0;
    for (std::pair<long long, long long> stone : stones) {
        res += stone.second;
    }
    return res;
}

int part_one() {
    std::vector<long long> stones {41078, 18, 7, 0, 4785508, 535256, 8154, 447};
    for (long long i = 0; i < 25; i++) {
        std::vector<long long> new_stones;
        for (long long stone : stones) {
            std::string temp = std::to_string(stone);
            if (stone == 0) {
                new_stones.push_back(1);
            } else if (temp.length() % 2 == 0) {
                new_stones.push_back(std::stoll(temp.substr(0, temp.length() / 2)));
                new_stones.push_back(std::stoll(temp.substr(temp.length() / 2, temp.length() / 2)));
            } else {
                new_stones.push_back(stone * 2024);
            }
        }
        stones = new_stones;
    }
    return stones.size();
}


int main() {
    
    long long res_one = part_one();
    long long res_two = part_two();
    std::cout << res_one << std::endl;
    std::cout << res_two << std::endl;
    return 0;
}