#pragma once

#include <gtest/gtest.h>
#include <Basic/Location.h>
#include <Compiler/Compiler.h>
#include <Support/Support.h>

namespace clice {

namespace test {

llvm::StringRef source_dir();

llvm::StringRef resource_dir();

}  // namespace test

class Annotation {
public:
    Annotation(llvm::StringRef source) : m_source() {
        m_source.reserve(source.size());

        uint32_t line = 0;
        uint32_t column = 0;

        for(uint32_t i = 0; i < source.size();) {
            auto c = source[i];

            if(c == '@') {
                i += 1;
                auto key = source.substr(i).take_until([](char c) { return c == ' '; });
                assert(!locations.contains(key) && "duplicate key");
                locations.try_emplace(key, line, column);
                continue;
            }

            if(c == '$') {
                assert(i + 1 < source.size() && source[i + 1] == '(' && "expect $(name)");
                i += 2;
                auto key = source.substr(i).take_until([](char c) { return c == ')'; });
                i += key.size() + 1;
                assert(!locations.contains(key) && "duplicate key");
                locations.try_emplace(key, line, column);
                continue;
            }

            if(c == '\n') {
                line += 1;
                column = 0;
            } else {
                column += 1;
            }

            i += 1;
            m_source.push_back(c);
        }
    }

    llvm::StringRef source() const {
        return m_source;
    }

    proto::Position position(llvm::StringRef key) const {
        return locations.lookup(key);
    }

private:
    std::string m_source;
    llvm::StringMap<proto::Position> locations;
};

template <typename Callback>
inline void foreachFile(std::string name, const Callback& callback) {
    llvm::SmallString<128> path;
    path += test::source_dir();
    path::append(path, name);
    std::error_code error;
    fs::directory_iterator iter(path, error);
    fs::directory_iterator end;
    while(!error && iter != end) {
        auto file = iter->path();
        auto buffer = llvm::MemoryBuffer::getFile(file);
        if(!buffer) {
            llvm::outs() << "failed to open file: " << buffer.getError().message() << file << "\n";
            // TODO:
        }
        auto content = buffer.get()->getBuffer();
        callback(file, content);
        iter.increment(error);
    }
}

class Tester {
public:
    CompliationParams params;
    std::unique_ptr<llvm::vfs::InMemoryFileSystem> vfs;
    ASTInfo info;

    /// Annoated locations.
    std::vector<std::string> sources;
    llvm::StringMap<proto::Position> locations;

public:
    Tester(llvm::StringRef file, llvm::StringRef content) {
        params.path = file;
        params.content = annoate(content);
        vfs = std::make_unique<llvm::vfs::InMemoryFileSystem>();
    }

    void addFile(llvm::StringRef name, llvm::StringRef content) {
        vfs->addFile(name, 0, llvm::MemoryBuffer::getMemBufferCopy(annoate(content)));
    }

    llvm::StringRef annoate(llvm::StringRef content) {
        auto& source = sources.emplace_back();
        source.reserve(content.size());

        uint32_t line = 0;
        uint32_t column = 0;
        for(uint32_t i = 0; i < content.size();) {
            auto c = content[i];

            if(c == '@') {
                i += 1;
                auto key = content.substr(i).take_until([](char c) { return c == ' '; });
                assert(!locations.contains(key) && "duplicate key");
                locations.try_emplace(key, line, column);
                continue;
            }

            if(c == '$') {
                assert(i + 1 < content.size() && content[i + 1] == '(' && "expect $(name)");
                i += 2;
                auto key = content.substr(i).take_until([](char c) { return c == ')'; });
                i += key.size() + 1;
                assert(!locations.contains(key) && "duplicate key");
                locations.try_emplace(key, line, column);
                continue;
            }

            if(c == '\n') {
                line += 1;
                column = 0;
            } else {
                column += 1;
            }

            i += 1;
            source.push_back(c);
        }

        return source;
    }

    Tester& run(const char* standard = "-std=c++20") {
        params.vfs = std::move(vfs);

        llvm::SmallVector<const char*> args = {
            "clang++",
            standard,
            params.path.c_str(),
            "-resource-dir",
            test::resource_dir().data(),
        };
        params.args = args;

        auto info = compile(params);
        if(!info) {
            llvm::errs() << "Failed to build AST\n";
            std::terminate();
        }

        this->info = std::move(*info);
        return *this;
    }

    Tester& fail(const auto& lhs, const auto& rhs, std::source_location loc) {
        auto msg =
            std::format("expect: {}, actual: {}\n", json::serialize(lhs), json::serialize(rhs));
        ::testing::internal::AssertHelper(::testing ::TestPartResult ::kNonFatalFailure,
                                          loc.file_name(),
                                          loc.line(),
                                          msg.c_str()) = ::testing ::Message();
        return *this;
    }

    Tester& equal(const auto& lhs,
                  const auto& rhs,
                  std::source_location loc = std::source_location::current()) {
        if(!support::equal(lhs, rhs)) {
            return fail(lhs, rhs, loc);
        }
        return *this;
    }

    Tester& expect(llvm::StringRef name,
                   clang::SourceLocation loc,
                   std::source_location current = std::source_location::current()) {
        auto pos = locations.lookup(name);
        auto presumed = info.srcMgr().getPresumedLoc(loc);
        /// FIXME:
        equal(pos, proto::Position{presumed.getLine() - 1, presumed.getColumn() - 1}, current);
        return *this;
    }
};

}  // namespace clice

